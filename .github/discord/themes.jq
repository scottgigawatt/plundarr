#
# Copyright 2025-2026 Scott Gigawatt
#
# SPDX-License-Identifier: Apache-2.0
#
# themes.jq: Store project-specific Discord identities and bounded joke variants.
#
# Usage: Loaded by .github/scripts/discord-notifier.sh with image, profile,
#        notification type, outcome, and deterministic selection inputs.
#

{
  "colors": {
    "start": 0,
    "success": 5763719,
    "failure": 15548997,
    "warning": 16705372,
    "cancelled": 10070709,
    "skipped": 10070709,
    "neutral": 10070709
  },
  "images": {
    "Maraudarr": {
      "color": 11032055,
      "image-primary": {
        "name": "Compose Couture",
        "jokes": {
          "start": [
            "Compose couture is back at the sewing machine.",
            "The generator has fabric, patterns, and strong opinions."
          ],
          "success": [
            "A fresh generator, dressed to compose.",
            "The generator has finished its outfit and brought the pattern."
          ],
          "failure": [
            "The sewing machine has requested a manager.",
            "The generator has hit a seam it cannot explain away."
          ],
          "cancelled": [
            "The sewing machine is taking an intermission.",
            "The generator has stepped away from the fitting."
          ],
          "skipped": [
            "This pattern stayed on the cutting table.",
            "The generator kept its measuring tape in the drawer."
          ],
          "neutral": [
            "The fitting needs a clearer verdict.",
            "The sewing room would like an actual answer."
          ],
          "warning": [
            "The generator needs another fitting before the curtain rises.",
            "The sewing room has spotted a detail worth checking."
          ]
        }
      },
      "image-secondary": {
        "name": "Hades Shipping Department",
        "jokes": {
          "start": [
            "Your image is being prepared. Eternal shipping delays are not included.",
            "Hades has opened a shipping order with unusually optimistic timing."
          ],
          "success": [
            "The underworld finally shipped something besides eternal suffering.",
            "The shipping department has filed the paperwork under pleasantly surprising."
          ],
          "failure": [
            "Shipping is delayed. Please direct complaints to the nearest screaming void.",
            "The shipping department has escalated this to someone with more horns."
          ],
          "cancelled": [
            "The shipping department has stopped loading the cart.",
            "Hades has returned this order to the waiting room."
          ],
          "skipped": [
            "No shipment was booked with the underworld today.",
            "The shipping demons left the packing tape untouched."
          ],
          "neutral": [
            "The shipping department needs a less cryptic answer.",
            "Hades has requested a status report with actual words."
          ],
          "warning": [
            "The shipping department found paperwork that needs attention.",
            "Hades recommends checking the label before signing for this one."
          ]
        }
      }
    }
  },
  "docs": {
    "subject": "Plundarr",
    "image": "Maraudarr",
    "name": "Compose Yourself, Queen",
    "jokes": {
      "start": [
        "The chart room is putting its reading glasses on.",
        "The developer charts have arrived for their table read."
      ],
      "success": [
        "The charts are composed. The queen is impressed.",
        "A new chapter, with fewer dramatic pauses."
      ],
      "failure": [
        "The chart room has requested an editor with strong boundaries.",
        "The table read has reached an unexpectedly difficult scene."
      ],
      "cancelled": [
        "The chart room has called an intermission.",
        "The table read will resume another time."
      ],
      "skipped": [
        "The charts stayed on the rehearsal stand.",
        "No new chapter took the stage this time."
      ],
      "neutral": [
        "The chart room is waiting for a definite ending.",
        "The editor has circled the verdict in pencil."
      ],
      "warning": [
        "The chart room needs a closer read of the notes.",
        "The editor has a question before the curtain call."
      ]
    }
  }
} as $catalog
| $catalog.images[$image_name] as $image
| (if $notification_type | startswith("docs-") then
    if $profile == "docs" then $catalog.docs else null end
  elif $profile == "image-primary" or $profile == "image-secondary" then
    $image[$profile] + {subject: $image_name}
  else null end) as $identity
| ($notification_type | startswith("docs-")) as $docs
| (if $docs then "documentation update" else "image pipeline" end) as $noun
| {start: "started", success: (if $docs then "published" else "published" end), failure: "failed", cancelled: "cancelled", skipped: "skipped", neutral: "ended with a neutral result", warning: "needs attention"}[$outcome] as $state
| if $identity == null or $identity.jokes[$outcome] == null or $state == null then
    error("unsupported Discord notification definition")
  else
    {
      username: ($identity.subject + (if $docs then " Docs" else " Image Builds" end) + " • " + $identity.name),
      subject: $identity.subject,
      title: (({start: "🔨", success: "✅", failure: "❌", cancelled: "⏹️", skipped: "⏭️", neutral: "ℹ️", warning: "⚠️"}[$outcome]) + " " + $identity.subject + " " + (if $outcome == "success" and ($docs | not) then "image" else $noun end) + " " + $state),
      footer: ($identity.name + (if $docs then " • documentation updates" else " • image builds" end)),
      color: (if $outcome == "start" then (if $docs then $catalog.images[$catalog.docs.image].color else $image.color end) else $catalog.colors[$outcome] end),
      message: $identity.jokes[$outcome][$selection % ($identity.jokes[$outcome] | length)]
    }
  end
