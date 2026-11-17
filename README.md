# guywood.net

The photo blog that used to live on Tumblr, now a GitHub Pages site built with Jekyll.
GitHub rebuilds the site automatically a minute or two after every change to `master`.

## Adding a new post

You can do all of this on github.com, including from a phone browser.

1. **Upload the photo.** Open the `photos` folder, choose **Add file → Upload files**,
   and drop in your picture. Give it a simple name with no spaces, such as
   `lisbon-tram.jpg`. Commit the upload.

2. **Create the post.** Open the `_posts` folder, choose **Add file → Create new file**,
   and name it with today's date followed by a short name:

   ```
   2026-11-20-lisbon-tram.md
   ```

3. **Paste this in and fill it out:**

   ```
   ---
   title: "Eléctrico 28, Lisboa"
   image: /photos/lisbon-tram.jpg
   ---
   Eléctrico 28, Lisboa

   (Tram 28, Lisbon)
   ```

   - `title` is used for the archive and the browser tab.
   - `image` is the photo you uploaded, starting with `/photos/`.
   - Everything below the second `---` is the caption. Leave a blank line between paragraphs.
     You can use Markdown, such as `*italics*` or `[a link](https://example.com)`.

4. **Commit the file.** The post appears at the top of the home page, in the archive,
   and in the RSS feed.

### Optional extras

- **A text-only post:** leave out the `image:` line.
- **A specific time:** add a line such as `date: 2026-11-20 18:30:00 -0500`.
- **Dates in the future are hidden.** A post dated after today won't show up, even once that day arrives, until the next change to the site triggers a rebuild.
- **A draft:** put the file in a `_drafts` folder instead. It won't be published until you move it to `_posts`.
- **Editing or deleting:** open the post's file in `_posts` and use the pencil or trash icon.

## Layout of the repo

| Path | What it is |
| --- | --- |
| `_posts/` | One file per post |
| `photos/` | The images |
| `_layouts/`, `_includes/` | Page templates |
| `style.css` | The look, based on the old Tumblr "Effector" theme |
| `index.html`, `archive/` | Home page and archive grid |
| `404.html` | Not-found page; also forwards old Tumblr links to their new addresses |

Posts carried over from Tumblr keep their old numbers in the address, such as `/post/47525232458/`,
so existing links still work.
