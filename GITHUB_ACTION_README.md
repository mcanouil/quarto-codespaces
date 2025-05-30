# GitHub Action Setup

## Automated Morning Briefing Generation

This repository includes a GitHub Action that automatically generates the Morning Briefing every day at 7:30 AM Berlin Time.

### Features

- **Daily Automation**: Runs every day at 7:30 AM Berlin Time (5:30 UTC summer / 6:30 UTC winter) via cron schedule
- **Manual Trigger**: Can be manually triggered via GitHub's workflow dispatch
- **Font Installation**: Automatically installs BundesSans Web fonts before rendering
- **PDF Generation**: Creates a professional PDF using Quarto and Typst
- **Email Delivery**: Automatically sends the Morning Briefing via email to configured recipients
- **Artifact Storage**: Saves generated PDFs as artifacts for 30 days
- **Git Integration**: Commits updated PDFs back to the repository
- **Weekly Releases**: Creates GitHub releases every Monday with the latest briefing

### Workflow Steps

1. **Environment Setup**: Installs R, Pandoc, Quarto, and Typst
2. **System Dependencies**: Installs required system libraries for PDF generation
3. **Font Installation**: Copies BundesSans Web fonts to system font directory
4. **Package Management**: Restores R packages using renv
5. **Document Rendering**: Generates the Morning Briefing PDF
6. **Artifact Upload**: Saves PDF as a downloadable artifact
7. **Email Delivery**: Sends the PDF via email to configured recipients
8. **Git Commit**: Commits the updated PDF to the repository
9. **Release Creation**: Creates weekly releases (Mondays only)

### Configuration

To customize the schedule, edit the cron expression in `.github/workflows/render-briefing.yml`:

```yaml
schedule:
  # Current: 7:30 AM Berlin Time 
  - cron: '30 5 * * *'  # Summer time (CEST = UTC+2)
  
  # Alternative for winter time (CET = UTC+1):
  # - cron: '30 6 * * *'
  
  # Other examples:
  # 6:00 AM Berlin: '0 4 * * *' (summer) / '0 5 * * *' (winter)
  # 8:00 AM Berlin: '0 6 * * *' (summer) / '0 7 * * *' (winter)
  # Weekdays only at 7:30 AM: '30 5 * * 1-5'
```

### Timezone Considerations

The cron schedule is configured for Berlin Time:

- **Current Setting**: 7:30 AM Berlin Time
- **Summer (CEST, UTC+2)**: `'30 5 * * *'` (5:30 UTC)
- **Winter (CET, UTC+1)**: `'30 6 * * *'` (6:30 UTC)

**Note**: GitHub Actions use UTC time. The current configuration uses summer time. 
You may need to manually adjust the cron expression when switching between summer/winter time.

Other timezone examples:
- **EST (UTC-5)**: 7:30 AM EST = 12:30 PM UTC → `'30 12 * * *'`
- **PST (UTC-8)**: 7:30 AM PST = 3:30 PM UTC → `'30 15 * * *'`

### Manual Execution

You can manually trigger the workflow:

1. Go to the "Actions" tab in your GitHub repository
2. Select "Render Morning Briefing" workflow
3. Click "Run workflow" button
4. Choose the branch and click "Run workflow"

### Artifacts and Releases

- **Daily Artifacts**: Each run creates a numbered artifact (e.g., `morning-briefing-123`)
- **Weekly Releases**: Every Monday, a GitHub release is created with the latest PDF
- **Repository Updates**: The main `morning_briefing.pdf` file is updated with each run

### Dependencies

The workflow installs all necessary dependencies automatically:

- **R packages**: Managed via `renv.lock`
- **System libraries**: libcurl, libssl, libxml2, fontconfig, etc.
- **Fonts**: BundesSans Web font family
- **Tools**: Quarto, Typst, Pandoc
- **Email Service**: SMTP configuration for automated delivery

### Email Configuration

For automatic email delivery, configure these repository secrets:

- **`EMAIL_USERNAME`**: Sender email address (e.g., Gmail)
- **`EMAIL_PASSWORD`**: App password for email account
- **`EMAIL_RECIPIENTS`**: Comma-separated list of recipient emails

See [EMAIL_SETUP.md](EMAIL_SETUP.md) for detailed email configuration instructions.

### Troubleshooting

If the workflow fails:

1. Check the Actions tab for error logs
2. Verify that all required files are present in the repository
3. Ensure the `renv.lock` file is up to date
4. Check that font files are available in the `fonts/` directory

### Security

The workflow uses:

- `actions/checkout@v4` for repository access
- `contents: write` permission for committing PDFs
- Cached R packages for faster execution
- No sensitive data or API keys required
