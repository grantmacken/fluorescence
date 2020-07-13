<!--
{
  "status": "created",
  "uid": "http://xq/gmack.nz/article/respect-the-cascade"
}
-->

In the not too distant past, web development was riddled with CSS hacks and resets to correct browser differences.
CSS generators like [sass](https://sass-lang.com/), and [postcss](https://postcss.org/) originated to add 'missing' or hard to use features to CSS. Frameworks like 'bootstrap' proliferated to create nicer buttons, structure your classes, create reusable
components etc. I don't think is overstating the case to say, prior to flexbox and grid, page layout was hair pulling
difficult and doubly so for pixel perfect fixated graphic designers.

How you do web development with CSS can lead to polarised perspectives.
With the increasingly popular Tailwind CSS framework, 
you can have a utility driven 'atomic' classes added directly to HTML

```html
<button class="bg-blue-500 text-white font-bold py-2 px-4 rounded">
  Button
</button>
```

In the opposite corner, you have the 'classless' CSS frameworks, like
[picnicss](https://picnicss.com/) which try to avoid presentational classes mixed into HTML
elements. Perhaps unsurprisingly you have framework like
[cube-css](https://piccalil.li/blog/cube-css/) which attempts to marry these
opposing perspectives together.

In the my time I have coded a few cascading-style-sheets,
and tried a few frameworks, however now I develop without a framework. 

## A work in progress 

Here I will try to document the how and why of my 
Cascading Style Sheets

### index sheet

From my index sheet, other style sheets get loaded

```css
@import "fonts";
@import "variables";
@import "layout";
@import "lists";
@import "typography";
@import "code";
```


### fonts sheet

I am using 'IBM plex' series of fonts
The CSS for the Sans font is below

```css
@font-face {
  font-family: 'IBM Plex Sans';
  font-style: normal;
  font-weight: 400;
  src: local('IBM Plex Sans'), local('IBMPlexSans'),
    url('../fonts/ibm-plex-sans-v7-latin-regular.woff2') format('woff2'),
    url('../fonts/ibm-plex-sans-v7-latin-regular.woff') format('woff');
  font-display: swap;
 }
```


As you can see I serve them directly from my server.
**woff2** fonts are pretty small, with the mono font weighing in at
13.7kb and the serif at 18.7kg.


Although the font size is not large, and my site uses HTTP2, 
to speed up the font loading loading I use a link preload in my document head.
I could also preload the fonts, but I've given that a miss.


```xquery
  element link {
    attribute href { '/styles/fonts' },
    attribute rel { 'preload' },
    attribute as { 'style' }
    }
```

I am not sure, if this has any impact. 
I'll figure a way to test and report back.

If you use fonts like this, one thing to keep in mind is
the font URL is relative to the CSS file and not the loading HTML page.

I have found the [google-webfonts-helper](https://google-webfonts-helper.herokuapp.com/fonts)
the best place to get fonts. 
To get a smaller sized woff2 make sure you only use the subset you require.
If want to get smaller font sizes, by selecting only the chars you require, then 
the [fontsquirell generator](https://www.fontsquirrel.com/tools/webfont-generator) is the place to head to.

### variables sheet

I use 'CSS custom properties' to theme my site.
At the moment I am using the 'nord' color scheme.

The start of the sheet I define my color scheme.

```css
:root {
   --dark1: hsla(220, 16%, 22%, 1);
   /* ... */
   --light3: hsla(218, 27%, 94%, 1);
   /* ... */
```

I then set some baseline custom properties.

```
   /*  BASELINE properties */
   --base-font-family: 'IBM Plex Serif', 'Georgia', Times, serif;
   --base-font-size: min(max(1rem, 4vw), 22px);
   --base-line-height: 1.5;
   --base-color: var(--dark1);
   --base-background: var(--light3);
```

Later on in the typography sheet these baseline custom properties are set high in
the HTML element tree, so any element children inherit these styles.

```
body {
  font-family: var(--base-font-family);
  color: var(--base-color);
  background-color: var(--base-background);
  font-size:  var(--base-font-size);
  line-height: var(--base-line-height);
}
```

### layout sheet

TODO

### typography sheet

HTML markup generated from **markdown** will have no element class attributes,
therefore defining 'styles' for html elements can depend on the **relationship** between elements.

```
article * + * {
 margin-top: 1.5em;
}

p + p {
text-indent: .5em;
}
```



TODO
