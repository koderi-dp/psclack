# Mirrors clack-example/autocomplete.js — run: pwsh .\autocomplete.ps1
$modulePath = Join-Path $PSScriptRoot '..\PsClack.psd1'
Import-Module $modulePath -Force

Show-PsClackIntro -Message ' autocomplete '

$framework = Read-PsClackAutocompletePrompt `
    -Message 'Pick a web framework (type to filter).' `
    -Placeholder 'e.g. next, vue, rust…' `
    -MaxItems 8 `
    -Options @(
        [pscustomobject]@{ Label = 'Next.js'; Value = 'next'; Hint = 'React, SSR' }
        [pscustomobject]@{ Label = 'Remix'; Value = 'remix'; Hint = 'React, nested routes' }
        [pscustomobject]@{ Label = 'Nuxt'; Value = 'nuxt'; Hint = 'Vue, SSR' }
        [pscustomobject]@{ Label = 'SvelteKit'; Value = 'sveltekit'; Hint = 'Svelte, SSR' }
        [pscustomobject]@{ Label = 'SolidStart'; Value = 'solid-start'; Hint = 'Solid, islands' }
        [pscustomobject]@{ Label = 'Astro'; Value = 'astro'; Hint = 'content sites' }
        [pscustomobject]@{ Label = 'TanStack Start'; Value = 'tanstack-start'; Hint = 'React, full-stack' }
        [pscustomobject]@{ Label = 'Hono'; Value = 'hono'; Hint = 'edge, minimal' }
        [pscustomobject]@{ Label = 'Fastify'; Value = 'fastify'; Hint = 'Node HTTP' }
        [pscustomobject]@{ Label = 'Elysia'; Value = 'elysia'; Hint = 'Bun, TypeScript' }
    ) `
    -PassThru

if ($framework.Cancelled) {
    Show-PsClackCancel -Message 'Operation cancelled'
    return
}

Show-PsClackOutro -Message ('Selected: {0}' -f $framework.Value)
