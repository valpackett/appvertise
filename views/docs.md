# Documentation

## How to show ads and get paid

First, log in to Appvertise with your App.net account and create a key for your app (website, whatever).

You SHOULD use a new key for each app.

Second, implement the following algorithm in your app:

1. [Get the last post](http://developers.app.net/docs/resources/post/streams/#retrieve-posts-created-by-a-user) by [@appvertise](https://alpha.app.net/appvertise). Don't forget the `include_post_annotations` parameter.
2. Display it as the ad in whatever place is appropriate for your design.

You SHOULD check the [annotation](http://developers.app.net/docs/meta/annotations/) of type `com.floatboth.appvertise.ad`.
It contains the paid-through date/time under the `paid_through` key.
Compare it with current time.
If `paid_through` is in the past, it's pointless to show the ad.

The ad is a post that contains:

- the ad text;
- the 130x100 image in [standard oEmbed format](https://github.com/appdotnet/object-metadata/blob/master/annotations/net.app.core.oembed.md);
- a [link entity](http://developers.app.net/docs/meta/entities/#links) that wraps the whole text and points to the URL that will credit your key when users click it -- **if you append your key as the `key` query parameter to it**.

You MUST display all the things, including the image (unless it's technically impossible, like if you're making a client for Nokia 3210.)

You SHOULD replace " [appvertise-it.herokuapp.com]" with "" when displaying the text if you're taking it from the post's `text` field, but you can also just take the URL and the text from the link entity.

So, for example, if the last post looks like this:

    {
      "entities":{
        "links":[
          {
            "url":"http:\/\/appvertise-it.herokuapp.com\/ads\/51323985298cba0002000002\/click",
            "text":"floatboth.com \u2013 the best blog in the world.",
            "pos":0, "len":43, "amended_len":73
          }
        ]
      },
      "text":"floatboth.com \u2013 the best blog in the world. [appvertise-it.herokuapp.com]",
      "annotations":[
        {
          "type":"com.floatboth.appvertise.ad",
          "value":{ "paid_through":"2013-03-02 19:15:36 +0000" }
        },
        {
          "type":"net.app.core.oembed",
          "value":{
            "url":"http://mfwb.us/HBjM",
            # ...
          }
        }
      ],
      # ...
    }

The HTML for the ad might look like this:

    <figure class="ad">
      <a href="http://appvertise-it.herokuapp.com/ads/51323985298cba0002000002/click?key=51423985288cba0002003002">
        <img src="http://mfwb.us/HBjM" alt="">
        <figcaption>floatboth.com \u2013 the best blog in the world.</figcaption>
      </a>
    </figure>

And it should be displayed if `2013-03-02 19:15:36 +0000` is in the future.

When a user of your app clicks the link, we record it (if it's not the same IP clicking too often) for your key.

When the `paid-through` time comes, we take the amount of money that was paid for the ad, take a 30% cut, calculate how much should go to which key based on clicks, credit these keys with bitcoins.

If you have earned at least 0.01 BTC, you can withdraw this money to your bitcoin address.

## Privacy Policy

Appvertise does not store any personal data.

## Terms of Service

Appvertise is a client for App.net, so [App.net terms](https://account.app.net/legal/terms/) apply.

The service is experimental.
