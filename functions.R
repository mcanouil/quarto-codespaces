# Morning Briefing Functions
# =========================

# Load required libraries
library(xml2)
library(httr2)
library(yahoofinancer)
library(ggplot2)
library(gt)
library(dplyr)
library(scales)

# Base function to fetch and parse RSS feed
fetch_rss_feed <- function(url) {
    response <- request(url) |> req_perform()
    feed_content <- resp_body_string(response)
    feed <- read_xml(feed_content)

    return(list(
        headlines = xml_text(xml_find_all(feed, "//item/title")),
        links = xml_text(xml_find_all(feed, "//item/link")),
        descriptions = xml_text(xml_find_all(feed, "//item/description"))
    ))
}

# Function to print news articles
print_news <- function(headlines, links, max_count = NULL) {
    count <- length(headlines)
    if (!is.null(max_count)) {
        count <- min(max_count, count)
        headlines <- headlines[1:count]
        links <- links[1:count]
    }

    for (i in 1:count) {
        cat(paste0(i, ". [", headlines[i], "](", links[i], ")\n\n"))
    }
}

# Function to get financial data and calculate changes
get_financial_indicator <- function(symbol, name) {
    tryCatch(
        {
            # Get current data with timeout protection
            ticker <- Ticker$new(symbol)

            # Try different periods if 1y fails
            periods <- c("1y", "6mo", "3mo", "1mo")
            history <- NULL

            for (period in periods) {
                tryCatch(
                    {
                        history <- ticker$get_history(
                            period = period,
                            interval = "1d"
                        )
                        if (nrow(history) > 0) break
                    },
                    error = function(e) NULL
                )
            }

            if (is.null(history) || nrow(history) == 0) {
                cat("Warning: No data available for", symbol, "-", name, "\n")
                return(create_na_result(name))
            }

            current_price <- tail(history$close, 1)
            if (is.na(current_price) || current_price == 0) {
                return(create_na_result(name))
            }

            # Calculate changes with defensive programming
            n_rows <- nrow(history)

            # 1 day change
            price_1d <- if (n_rows >= 2) history$close[n_rows - 1] else NA
            change_1d <- calculate_change(current_price, price_1d)

            # 30 day change
            day_30_index <- max(1, n_rows - 30)
            price_30d <- if (n_rows >= 2) history$close[day_30_index] else NA
            change_30d <- calculate_change(current_price, price_30d)

            # YTD calculation
            current_year <- format(Sys.Date(), "%Y")
            ytd_start <- as.Date(paste0(current_year, "-01-01"))

            # Find the first trading day of the year
            history_dates <- as.Date(history$date)
            ytd_indices <- which(history_dates >= ytd_start)
            price_ytd <- if (length(ytd_indices) > 0) {
                history$close[min(ytd_indices)]
            } else {
                history$close[1]
            }
            change_ytd <- calculate_change(current_price, price_ytd)

            # 1 year change
            price_1y <- history$close[1]
            change_1y <- calculate_change(current_price, price_1y)

            # Format current price based on instrument type
            decimals <- if (grepl("USD|EUR", name)) 4 else 2

            return(data.frame(
                Indikator = name,
                Aktuell = round(current_price, decimals),
                "1T %" = format_change(change_1d),
                "30T %" = format_change(change_30d),
                "YTD %" = format_change(change_ytd),
                "1J %" = format_change(change_1y),
                check.names = FALSE
            ))
        },
        error = function(e) {
            cat("Error for", symbol, "-", name, ":", e$message, "\n")
            return(create_na_result(name))
        }
    )
}

# Helper function to create NA result
create_na_result <- function(name) {
    return(data.frame(
        Indikator = name,
        Aktuell = NA,
        "1T %" = NA,
        "30T %" = NA,
        "YTD %" = NA,
        "1J %" = NA,
        check.names = FALSE
    ))
}

# Helper function to calculate percentage change
calculate_change <- function(current, previous) {
    if (is.na(current) || is.na(previous) || previous == 0) {
        return(NA)
    }
    return((current - previous) / previous * 100)
}

# Helper function to format change values
format_change <- function(change) {
    if (is.na(change)) return(NA)
    return(round(change, 2))
}

# Function to create financial indicators table
create_financial_table <- function() {
    # Define financial indicators with working symbols
    indicators <- list(
        list(symbol = "^GDAXI", name = "DAX"),
        list(symbol = "^GSPC", name = "S&P 500"),
        list(symbol = "BZ=F", name = "Brent Oil"),
        list(symbol = "NG=F", name = "Natural Gas"),
        list(symbol = "EURUSD=X", name = "EUR/USD"),
        list(symbol = "^TNX", name = "US 10Y Treasury")
    )

    # Enhanced alternatives list
    alternatives <- list(
        "EURUSD=X" = c("EUR=X", "EURUSD", "6E=F"),
        "^TNX" = c("^TYX", "^FVX", "^IRX"),
        "NG=F" = c("^NG", "TTF=F")
    )

    # Function to try multiple symbols
    get_indicator_with_alternatives <- function(primary_symbol, name) {
        # Try primary symbol first
        result <- get_financial_indicator(primary_symbol, name)
        if (!is.null(result) && !all(is.na(result[2:6]))) {
            return(result)
        }

        # Try alternatives if available
        if (primary_symbol %in% names(alternatives)) {
            for (alt_symbol in alternatives[[primary_symbol]]) {
                cat("Trying alternative symbol", alt_symbol, "for", name, "\n")
                result <- get_financial_indicator(alt_symbol, name)
                if (!is.null(result) && !all(is.na(result[2:6]))) {
                    return(result)
                }
            }
        }

        # Return NULL if all attempts failed
        return(NULL)
    }

    # Collect all data
    indicator_data <- NULL
    for (ind in indicators) {
        data <- get_indicator_with_alternatives(ind$symbol, ind$name)
        if (!is.null(data)) {
            indicator_data <- rbind(indicator_data, data)
        }
    }

    # Create styled table
    if (!is.null(indicator_data) && nrow(indicator_data) > 0) {
        indicator_data %>%
            gt() %>%
            tab_source_note(
                source_note = paste(
                    "Stand:",
                    format(Sys.time(), "%d.%m.%Y %H:%M", tz = "Europe/Berlin")
                )
            ) %>%
            fmt_number(
                columns = "Aktuell",
                decimals = 2
            ) %>%
            fmt_percent(
                columns = c("1T %", "30T %", "YTD %", "1J %"),
                decimals = 1,
                scale_values = FALSE
            ) %>%
            data_color(
                columns = c("1T %", "30T %", "YTD %", "1J %"),
                colors = scales::col_numeric(
                    palette = c("#d73027", "#f7f7f7", "#1a9850"),
                    domain = c(-50, 50)
                )
            ) %>%
            tab_style(
                style = cell_text(weight = "bold"),
                locations = cells_column_labels()
            ) %>%
            tab_style(
                style = cell_text(weight = "bold"),
                locations = cells_body(columns = "Indikator")
            ) %>%
            cols_align(
                align = "center",
                columns = c("Aktuell", "1T %", "30T %", "YTD %", "1J %")
            ) %>%
            tab_options(
                table.font.size = px(12),
                heading.title.font.size = px(16),
                heading.subtitle.font.size = px(12),
                table.font.names = "BundesSans Web"
            )
    } else {
        cat("Fehler beim Laden der Marktdaten.\n\n")
    }
}

# Function to get filtered industry news
get_industry_news <- function(max_stories = 5) {
    # Industry keywords (German only with synonyms and company names)
    industry_keywords <- c(
        # Chemie
        "chemie",
        "chemisch",
        "chemiekonzern",
        "chemieindustrie",
        "chemieunternehmen",
        "basf",
        "bayer",
        "covestro",
        "evonik",
        "lanxess",
        "wacker",

        # Automotive
        "auto",
        "automobil",
        "autobauer",
        "automobilindustrie",
        "fahrzeug",
        "pkw",
        "volkswagen",
        "bmw",
        "mercedes",
        "daimler",
        "porsche",
        "audi",
        "opel",
        "automobilhersteller",
        "autohersteller",
        "fahrzeughersteller",

        # Stahl
        "stahl",
        "stahlkonzern",
        "stahlindustrie",
        "stahlhersteller",
        "stahlproduktion",
        "thyssenkrupp",
        "salzgitter",
        "metall",
        "metallurgie",
        "hüttenwerk"
    )

    # Fetch and filter industry news
    unternehmen_feed <- fetch_rss_feed(
        "https://www.handelsblatt.com/contentexport/feed/unternehmen"
    )

    # Create filter pattern
    filter_pattern <- paste(industry_keywords, collapse = "|")

    # Filter news based on headlines and descriptions
    search_text <- paste(
        unternehmen_feed$headlines,
        unternehmen_feed$descriptions
    )
    matches <- grepl(filter_pattern, search_text, ignore.case = TRUE)

    filtered_headlines <- unternehmen_feed$headlines[matches]
    filtered_links <- unternehmen_feed$links[matches]

    # Print filtered headlines (max stories)
    if (length(filtered_headlines) > 0) {
        print_news(filtered_headlines, filtered_links, max_stories)
    } else {
        cat(
            "Keine relevanten Nachrichten aus den Bereichen Chemie, Automotive oder Stahl gefunden.\n\n"
        )
    }
}

# Function to get economic calendar events for Germany
get_economic_calendar <- function() {
    tryCatch(
        {
            # This is just dummy data
            get_basic_economic_indicators()
        },
        error = function(e) {
            cat(
                "Fehler beim Laden des Wirtschaftskalenders: ",
                e$message,
                "\n\n"
            )
        }
    )
}

# Function to get basic economic indicators for Germany
get_basic_economic_indicators <- function() {
    tryCatch(
        {
            # Create a simple table with key German economic indicators
            current_date <- format(Sys.Date(), "%d.%m.%Y")

            # Basic economic events (this could be expanded with real API data)
            events <- data.frame(
                Datum = c(
                    format(Sys.Date(), "%d.%m"),
                    format(Sys.Date() + 1, "%d.%m"),
                    format(Sys.Date() + 2, "%d.%m")
                ),
                Zeit = c("10:00", "14:00", "09:00"),
                Event = c(
                    "ifo Geschäftsklimaindex",
                    "EZB Zinsentscheidung",
                    "Arbeitslosenquote"
                ),
                Wichtigkeit = c("Hoch", "Hoch", "Mittel"),
                stringsAsFactors = FALSE
            )

            # Create styled table
            events %>%
                gt() %>%
                cols_align(
                    align = "center",
                    columns = c("Datum", "Zeit", "Wichtigkeit")
                ) %>%
                cols_align(
                    align = "left",
                    columns = "Event"
                ) %>%
                data_color(
                    columns = "Wichtigkeit",
                    colors = scales::col_factor(
                        palette = c("lightgreen", "yellow", "lightcoral"),
                        domain = c("Niedrig", "Mittel", "Hoch")
                    )
                ) %>%
                tab_style(
                    style = cell_text(weight = "bold"),
                    locations = cells_column_labels()
                ) %>%
                tab_options(
                    table.font.size = px(12),
                    heading.title.font.size = px(14),
                    heading.subtitle.font.size = px(11),
                    table.font.names = "BundesSans Web"
                )
        },
        error = function(e) {
            cat(
                "Fehler beim Erstellen der Indikator-Tabelle: ",
                e$message,
                "\n\n"
            )
        }
    )
}
