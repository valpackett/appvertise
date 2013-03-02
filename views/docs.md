# Documentation

## How to show ads and get paid

First, log in to Appvertise, create a key and copy it.

Second, implement the following algorithm in your app/website/whatever:

1. [Get the last post](http://developers.app.net/docs/resources/post/streams/#retrieve-posts-created-by-a-user) by [@appvertise](https://alpha.app.net/appvertise). Don't forget the `include_post_annotations` parameter.
2. Check the [annotation](http://developers.app.net/docs/meta/annotations/) of type `com.floatboth.appvertise.ad`. It contains the paid-through date/time under the `paid_through` key. Compare it with current time. If `paid_through` is in the past, it's pointless to show the ad.
3. Otherwise, display the ad. 

The ad is a post that contains:

- the ad text;
- the 130x100 image in [standard oEmbed format](https://github.com/appdotnet/object-metadata/blob/master/annotations/net.app.core.oembed.md);
- a [link entity](http://developers.app.net/docs/meta/entities/#links) that wraps the whole text and points to the URL that will credit your key when users click it -- **if you append your key as the `key` query parameter to it**.

You're required to display all the things, including the image (unless it's technically impossible, like if you're making a client for Nokia 3210.)

## Privacy Policy

Appvertise does not store any personal data.

## Terms of Service

Appvertise is a client for App.net, so [App.net terms](https://account.app.net/legal/terms/) apply.
