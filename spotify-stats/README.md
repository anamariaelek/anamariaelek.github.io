# My Liked Songs — setup

A single static page (`index.html`) that logs into **your own** Spotify account in the browser, pulls your Liked Songs live, and renders the charts. No backend, no build step — just drop it in your GitHub Pages repo.

## Why login-only, just for you

Spotify tightened its developer API in 2024–2026:
- New apps stay in **Development Mode** forever unless you're a registered company with 250k+ monthly users — not attainable for a personal site.
- Development Mode apps work for **up to 5 explicitly allowlisted Spotify accounts** (you add each one by email in the dashboard).
- New apps no longer get **audio features** (energy, valence, danceability…) or **track popularity** — Spotify deprecated both in 2024–2026 with no replacement.

So this page is built to do one thing well: show *your* stats, live, when *you* visit it and sign in. It won't work for random visitors to your site — only accounts you allowlist.

## One-time setup (~10 minutes)

### 1. Create a Spotify app
1. Go to [developer.spotify.com/dashboard](https://developer.spotify.com/dashboard) and log in (you'll need **Spotify Premium** — Development Mode apps require the owner to have Premium).
2. Click **Create app**.
3. Fill in any name/description.
4. Under **Redirect URIs**, add the *exact* URL this page will live at, e.g.:
   ```
   https://anamaria.elek.hr/spotify-stats/
   ```
   It must match exactly (including trailing slash) or login will fail.
5. Under **APIs used**, select **Web API**.
6. Save.

### 2. Allowlist your own account
1. Open your new app → **Settings** → **User Management**.
2. Add your own Spotify account's email — even as the owner, Development Mode apps require every user (including you) to be on the allowlist.

### 3. Copy your Client ID
On the app's dashboard page, copy the **Client ID** (you do *not* need the Client Secret — this page uses the PKCE flow, which never needs a secret in browser code).

### 4. Configure the page
Open `index.html` and find this line near the top of the `<script>` block:

```js
const CLIENT_ID = "YOUR_SPOTIFY_CLIENT_ID_HERE";
```

Replace it with your actual Client ID.

### 5. Deploy
Copy the `spotify-stats/` folder into your `anamariaelek.github.io` repo, commit, and push. It'll be live at:
```
https://anamaria.elek.hr/spotify-stats/
```

Optionally add a link to it from your homepage nav.

## Using it

Visit the page and click **Connect with Spotify**. It'll ask you to log in and approve read-only access to your saved tracks, then pull your full Liked Songs library and render everything client-side. Click **Reload latest data** any time to refresh with newly liked songs. **Disconnect** clears the session from that browser tab.

## Notes & limits

- **Genres** require one API call per unique artist (Spotify removed the batch endpoint for new apps in Feb 2026), so if you like songs from 200+ artists, initial load can take 15–30 seconds. The progress bar shows where it's at.
- **No audio features / no popularity** — these were deprecated for new Spotify apps. The "Audio Character" and popularity-based sections from the companion Jupyter notebook can't be reproduced live; that notebook (built from an Exportify CSV export) remains the way to get that data.
- **Nothing is stored.** Tokens live only in `sessionStorage` for that browser tab; there's no database, no analytics, no server.
- If you ever see a `403` error, it almost always means your Spotify account isn't on the app's allowlist yet (Step 2 above).
