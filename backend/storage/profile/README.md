# Profile storage (gitignored)

This directory holds the personal files JobTracker hands back through the
`/api/v1/profile` endpoints — kept here on the WSL filesystem instead of
checked into git so the binaries never touch the public repo.

```
storage/profile/
├── README.md                              ← this file (the only thing tracked)
├── cv/
│   ├── pt/
│   │   ├── CV_Bruno_Borlido_PT_Visual.pdf ← default — send this
│   │   └── CV_Bruno_Borlido_PT_ATS.docx   ← only when the form asks for .docx
│   └── en/
│       ├── CV_Bruno_Borlido_EN_Visual.pdf
│       └── CV_Bruno_Borlido_EN_ATS.docx
└── cover_letters/
    ├── template_pt.md
    └── template_en.md
```

## Updating the CV

Drop the new PDF/.docx into `cv/<lang>/` with the same filename and the
ProfileController will pick it up — no code change needed.

## Cover letter placeholders

The templates use mustache-style `{{tokens}}` that the generator fills
from the matched Offer. The "human" personalisation parts (specific
company hook, why-this-company paragraph) stay as `[bracketed prompts]`
for you to hand-edit before sending — the goal is to remove the
mechanical typing, not to write the heartfelt bit for you.

| Token                | Filled from                           |
|----------------------|---------------------------------------|
| `{{city}}`           | profile.yml `city` (fallback Aveiro)  |
| `{{date}}`           | today, locale-formatted               |
| `{{recipient_name}}` | left as a placeholder for you         |
| `{{company}}`        | `offer.company`                       |
| `{{position_title}}` | `offer.title`                         |
| `{{platform}}`       | `offer.source.name` or "your website" |
| `{{start_date}}`     | profile.yml `start_date`              |

If you want to add another token, edit the template + the generator's
`fill_tokens` hash in one place.
