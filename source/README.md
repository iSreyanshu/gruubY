## GrubY

A Ruby Telegram wrapper with:

- `GrubY::Client` (BotAPI runtime)
- `GrubY::TDLib::Client` (tdjson native runtime, pytdbot-inspired)

## Install

```bash
gem install gruubY
```

For local development:

```bash
bundle install
```

From this repo directly:

```bash
rake build
gem install ./gruubY-0.2.2.gem
```

## What Is New

- TDLib internals upgraded with a dedicated `TdJson` wrapper
- Decorator-style hooks for TDLib:
  - `initializer`
  - `finalizer`
  - `on_message`
- Queue workers and handler timeout support
- Better authorization lifecycle handling
- Multi-client support utility: `GrubY::TDLib::ClientManager`
- CI workflows for TDLib build and gem publish

## BotAPI Quick Start

```ruby
require_relative "lib/gruubY"

client = GrubY::Client.new("BOT_TOKEN")
client.on(:message, GrubY::Filters.command("start")) { |ctx| ctx.reply("Heya; Started!") }
client.run
```

The Bot API wrapper targets Telegram Bot API **10.5**. Telegram's endpoints are available through snake_case method names:

```ruby
client.send_message(chat_id, "Hello")
client.get_sticker_set(name: "example_by_bot")
client.set_my_settings(supports_inline_queries: true)
```

Call a method directly on the client when it has a convenience wrapper, or use `API#request` with the official method name and a parameter hash:

```ruby
client.api.request("getMe")
client.api.request("setMySettings", { supports_inline_queries: true })
client.api.raw("getMe") # Full Telegram response envelope, including "ok" and "result".
```

The wrapper returns Telegram's `result` value for regular calls and raises `GrubY::API::Error` when Telegram returns an unsuccessful response. Parameters containing hashes and arrays are JSON-encoded. Upload files using a path or an open IO object for file parameters:

```ruby
client.send_photo(chat_id, "photo.jpg")
File.open("photo.jpg", "rb") { |photo| client.send_photo(chat_id, photo) }
```

The recognized method names are exposed in `GrubY::API::OFFICIAL_METHODS`. Convenience methods with required positional arguments keep those signatures; newer or less common methods accept keyword arguments or a single parameter hash.

The available methods span update/webhook management; sending, forwarding and copying messages/media; chat administration, invites and forum topics; reactions and message editing; stickers; commands and bot settings; business accounts; gifts, Stars and payments; stories; inline mode; Passport; and games. Use the `GrubY::API::OFFICIAL_METHODS` list to inspect the exact endpoint names available in this release.

## Receiving Updates

`GrubY::Client` uses long polling by default. `getUpdates` and webhooks are mutually exclusive in Telegram; the wrapper exposes webhook management calls but does not run an HTTP webhook server for you.

```ruby
client = GrubY::Client.new(
  ENV.fetch("BOT_TOKEN"),
  polling_timeout: 30,
  allowed_updates: %w[message callback_query poll_answer]
)
client.run
```

Leave `allowed_updates` unset to let Telegram use its default update selection. To switch to webhooks, configure the endpoint with the Bot API and run your own HTTPS server:

```ruby
client.set_webhook(
  url: "https://example.com/telegram/webhook",
  secret_token: ENV.fetch("WEBHOOK_SECRET"),
  allowed_updates: %w[message callback_query]
)
puts client.get_webhook_info.inspect

# After stopping the webhook server, switch back to long polling:
client.delete_webhook(drop_pending_updates: false)
```

`example/bot.rb` demonstrates long polling and handlers. The `Update` type retains the original payload through `[]` and `to_h`; common message/query fields are also wrapped as objects.

## Bot API 10.5 Features

### New and expanded endpoints

Snake_case endpoint helpers are defined from the official endpoint list, including new 10.5 calls such as:

```ruby
client.set_my_settings(supports_inline_queries: true)
client.send_widget(chat_id: chat_id, html: "<div>Hello from a widget</div>")
client.send_shared_widget(chat_id: chat_id, widget_id: widget_id)
client.answer_widget_query(widget_query_id: query_id, data: "received")
client.get_unique_gift(name: gift_name)
```

`set_my_settings` can configure inline mode and callback-query behavior, guest/join-request queries, group/privacy permissions, business and bot management, private-chat topics, and the topic sidebar. Only pass the settings you intend to change:

```ruby
client.set_my_settings(
  supports_guest_queries: true,
  supports_join_request_queries: true,
  can_communicate_with_bots: false,
  callback_query_mode: "auto",
  has_topic_sidebar: true
)
```

`sendWidget` takes HTML in its `html` parameter, while `sendSharedWidget` takes a `widget_id`. Answer a widget interaction using its `widget_query_id` and optional string `data`:

```ruby
client.send_shared_widget(chat_id: chat_id, widget_id: shared_widget_id)
client.answer_widget_query(widget_query_id: query.id, data: "received")
```

Use the official Telegram documentation for each method's required fields and allowed values; the wrapper passes request parameters through without changing their meaning. Bot profile results include `active_usernames`, `inline_query_placeholder`, `needs_inline_query_location`, and `has_topic_sidebar`.

### Message updates and ephemeral messages

The full edit/delete endpoint family is available through snake_case methods:

```ruby
client.edit_message_text(chat_id, message_id, "Updated text")
client.edit_message_caption(chat_id: chat_id, message_id: message_id, caption: "Updated caption")
client.edit_message_media(chat_id: chat_id, message_id: message_id, media: input_media)
client.edit_message_reply_markup(chat_id: chat_id, message_id: message_id, reply_markup: markup)
client.edit_message_checklist(business_connection_id: connection_id, chat_id: chat_id,
                              message_id: message_id, checklist: checklist)
client.delete_message(chat_id, message_id)
client.delete_messages(chat_id, [message_id])
```

Ephemeral message operations are also exposed (`edit_ephemeral_message_text`, `edit_ephemeral_message_media`, `edit_ephemeral_message_caption`, `edit_ephemeral_message_reply_markup`, and `delete_ephemeral_message`). Their permissions, time limits, and parameter requirements are enforced by Telegram. Fields such as `receiver_user`, `ephemeral_message_id`, and `ephemeral_message_parameters` are preserved on message objects.

Other update operations include `edit_message_live_location`, `stop_message_live_location`, `edit_message_widget_data`, `edit_shared_widget_data`, `stop_poll`, `approve_suggested_post`, `decline_suggested_post`, `delete_message_reaction`, and `delete_all_message_reactions`.

### New API object types

Newer object types available through `GrubY::TypeRegistry::TYPE_NAMES` include:

- Bot and update objects: `BotFullInfo`, `Update`, `WebhookInfo`, `BotSubscriptionUpdated`, `ManagedBotUpdated`, `MessageGenerationStopped`.
- Widgets: `Widget`, `WidgetQuery`, `SharedWidgetQuery`, `WidgetQueryType`, `WidgetQueryTypeData`, `WidgetQueryTypeSignData`, `WidgetQueryTypeSentTransaction`, `WidgetQueryWallet`.
- Ephemeral and rich messages: `EphemeralMessageParameters`, `RichMessage`, `RichMessageButton`, `RichTextButton`, `RichTextTonAddress`, rich-block and input-rich-block types, and inline input-widget types.
- Communities and service messages: `Community`, `CommunityChatAdded`, `CommunityChatJoined`, `CommunityChatRemoved`, `PaidMessagesWaived`, `TonWalletTransfer`.
- Wallet and sharing types: `TonWalletCard`, `TonWalletCardSticker`, `TonNft`, `TonNftAttribute`, `EmojiType`, `EmojiTypeEmoji`, `EmojiTypeCustomEmoji`, `ChatShareTheme`, `ChatShareThemeEmoji`, `ChatShareThemeUniqueGift`, `ChatShareThemeBackdrop`, `ChatShareThemeBackdrops`.

Sticker types include `Sticker`, `StickerSet`, `InputSticker`, and `MaskPosition`. Types without a dedicated wrapper are represented by `GrubY::BaseObject` subclasses and preserve fields via `[]` and `to_h`.

`GrubY::Update` models the incoming update envelope. The individual update fields include regular/edited messages and channel posts, business/guest messages, reactions, inline and callback queries, shipping/pre-checkout queries, paid-media purchases, polls and poll answers, member changes, join requests, boosts, managed bot changes, widget queries, subscriptions, and stopped message generation. The `Message` model includes new guest-query, rich-message, widget, ephemeral, community, and TON transfer fields.

### Stickers and sticker sets

The API wrapper exposes the complete sticker endpoint family:

```ruby
client.send_sticker(chat_id, file_id)
sticker_set = client.get_sticker_set(name: "example_by_bot")
client.get_custom_emoji_stickers(custom_emoji_ids: ["5368324170671202286"])

# Sticker administration endpoints:
client.upload_sticker_file(user_id: user_id, sticker: sticker, sticker_format: "static")
client.create_new_sticker_set(user_id: user_id, name: "example_by_bot",
                              title: "Example", stickers: stickers, sticker_type: "regular")
client.add_sticker_to_set(user_id: user_id, name: "example_by_bot", sticker: sticker)
client.set_sticker_position_in_set(sticker: file_id, position: 0)
client.set_sticker_emoji_list(sticker: file_id, emoji_list: ["🙂"])
client.set_sticker_keywords(sticker: file_id, keywords: ["smile"])
client.delete_sticker_from_set(sticker: file_id)
client.delete_sticker_set(name: "example_by_bot")
```

The complete sticker method family is available: `send_sticker`, `get_sticker_set`, `get_custom_emoji_stickers`, `upload_sticker_file`, `create_new_sticker_set`, `add_sticker_to_set`, `set_sticker_position_in_set`, `delete_sticker_from_set`, `replace_sticker_in_set`, `set_sticker_emoji_list`, `set_sticker_keywords`, `set_sticker_mask_position`, `set_sticker_set_title`, `set_sticker_set_thumbnail`, `set_custom_emoji_sticker_set_thumbnail`, and `delete_sticker_set`.

Sticker methods requiring a sticker or set owner need the exact Telegram fields for the sticker format and bot ownership. See [Telegram sticker methods](https://core.telegram.org/bots/api#stickers). Sticker types such as `GrubY::Sticker`, `GrubY::StickerSet`, `GrubY::InputSticker`, and `GrubY::MaskPosition` are available.

The other API families are available the same way: messaging/media; chat administration, invites and forum topics; commands and bot settings; business accounts; gifts, Stars and payments; stories; inline mode; games; and Passport. Call any official method using the snake_case equivalent of its Telegram method name, and pass the documented parameters as keywords or a hash.

### Update handlers

Polling dispatches each update field as an event. Latest update fields include regular and edited messages/channel posts; business and guest messages; reactions; inline and callback queries; widget queries; shipping and pre-checkout queries; paid media; polls and poll answers; bot/chat member changes; join requests; boosts; managed bots; and subscription/message-generation updates.

```ruby
client.on_channel_post do |_app, post|
  puts "Channel post #{post.message_id}"
end

client.on_guest_message do |_app, message|
  result = {
    type: "article",
    id: "guest-reply",
    title: "Thanks",
    input_message_content: { message_text: "Thanks for your message." }
  }
  client.answer_guest_query(guest_query_id: message.guest_query_id, result: result)
end

client.on_poll_answer do |_app, answer|
  puts "Poll #{answer.poll_id}"
end

client.on_widget_query do |_app, query|
  puts "Widget query #{query.id}"
  client.answer_widget_query(widget_query_id: query.id, data: "received")
end

client.on_my_chat_member do |_app, status|
  puts "Bot membership changed in #{status.chat&.id}"
end
```

The `on_chat_member` and `on_my_chat_member` callbacks receive separate update types. The official subscription and stopped-generation update keys are `subscription` and `stopped_message_generation`; their handlers are named `on_bot_subscription_updated` and `on_message_generation_stopped`. Likewise, `managed_bot` is exposed through `on_managed_bot`. Some updates (including `chat_member`, reactions, and join requests) require the relevant chat permissions and explicit `allowed_updates` configuration. `example/bot.rb` includes these handlers and commands for editing messages, sending stickers, reading sticker sets, and querying the bot name.

## TDLib Quick Start

```ruby
client = GrubY::TDLib::Client.new(
  api_id: ENV.fetch("TD_API_ID").to_i,
  api_hash: ENV.fetch("TD_API_HASH"),
  bot_token: ENV["TD_BOT_TOKEN"],
  tdjson_path: ENV["TDJSON_PATH"],
  workers: 4,
  default_handler_timeout: 10
)

client.initializer do |update|
end

client.on_message do |message|
  # Message object from updateNewMessage
end

client.finalizer do |update|
end

client.on("clientReady") { puts "TDLib Ready" }
client.run
```

## TDLib Paths

Supported shared libraries:

- Linux: `libtdjson.so`
- macOS: `libtdjson.dylib`
- Windows: `tdjson.dll`

Provide via:

- `TDJSON_PATH` env var
- `tdjson_path:` constructor argument

## Telegram User Session String (Ruby)

Generate a reusable TDLib user session string:

```bash
TD_API_ID=12345 TD_API_HASH=xxxx ruby example/generate_user_session.rb
```

After login, script prints:

```bash
TD_USER_SESSION=<base64>
```

Reuse:

```ruby
cfg = GrubY::TDLib::UserSession.client_kwargs(ENV.fetch("TD_USER_SESSION"))
client = GrubY::TDLib::Client.new(**cfg, tdjson_path: ENV["TDJSON_PATH"])
client.run
```

## Framework Helpers

Enums:

```ruby
GrubY::Enums::ParseMode::MARKDOWN_V2
GrubY::Enums::ChatAction::TYPING
```

InlineKeyboard and WebApp:

```ruby
markup = GrubY::Keyboard.inline([
  [GrubY::Keyboard.button("Ping", "ping:1")],
  [GrubY::Keyboard.web_app_button("Open App", "https://example.com/app")]
])
client.send_message(chat_id, "Menu", reply_markup: markup)
```

Bound and Raw:

```ruby
bound = GrubY::Bound.bind(ctx)
bound[:send].call("hello")
bound[:raw].call("getMe")
GrubY::Raw.td_call!(td_client, { "@type": "getMe" })
```

Bound Objects:

```ruby
client.on(:message) do |ctx|
  msg = ctx.message
  msg.reply_text("pong")
  msg.reply_photo("file_id_or_url")
  msg.edit_text("updated")
  msg.react(reaction: [{ type: "emoji", emoji: "👍" }])
end
```

Dynamic type registry:

```ruby
# Hundreds of Telegram types are available as BaseObject subclasses
u = GrubY::VerificationStatus.new("is_verified" => true)
p u.to_h
```

## Enumerations

Enum groups are available under `GrubY::Enums`:

- `BlockList`, `BusinessSchedule`, `ButtonStyle`, `ChatAction`, `ChatEventAction`, `ChatJoinType`
- `ChatMemberStatus`, `ChatMembersFilter`, `ChatType`, `ClientPlatform`, `FolderColor`
- `MessageEntityType`, `MessageMediaType`, `MessageOriginType`, `MessageServiceType`, `MessagesFilter`
- `NextCodeType`, `PaidReactionPrivacy`, `ParseMode`, `PhoneCallDiscardReason`, `PhoneNumberCodeType`, `PollType`
- `PrivacyKey`, `ProfileColor`, `ProfileTab`, `ReplyColor`, `SentCodeType`, `StoriesPrivacyRules`, `UserStatus`
- `UpgradedGiftOrigin`, `GiftAttributeType`, `MediaAreaType`, `PrivacyRuleType`, `GiftForResaleOrder`
- `GiftPurchaseOfferState`, `GiftType`, `PaymentFormType`, `StickerType`, `MaskPointType`
- `SuggestedPostRefundReason`, `SuggestedPostState`

Example:

```ruby
GrubY::Enums::ParseMode::MARKDOWN_V2
GrubY::Enums::ChatType::SUPERGROUP
GrubY::Enums::ChatMemberStatus::ADMINISTRATOR
```

## Decorators

Decorators are supported on `GrubY::Client`:

- `on_message`, `on_edited_message`, `on_channel_post`, `on_edited_channel_post`
- `on_business_message`, `on_edited_business_message`, `on_guest_message`
- `on_deleted_messages`, `on_deleted_business_messages`
- `on_message_reaction_count`, `on_message_reaction`
- `on_business_connection`, `on_story`, `on_callback_query`, `on_chat_boost`
- `on_chat_join_request`, `on_chat_member_updated`, `on_chosen_inline_result`, `on_inline_query`
- `on_poll`, `on_poll_answer`, `on_pre_checkout_query`, `on_purchased_paid_media`, `on_shipping_query`, `on_user_status`
- `on_chat_member`, `on_my_chat_member`, `on_removed_chat_boost`, `on_widget_query`, `on_shared_widget_query`
- `on_bot_subscription_updated`, `on_message_generation_stopped`
- `on_start`, `on_stop`, `on_connect`, `on_disconnect`, `on_error`, `on_managed_bot`, `on_raw_update`

Example:

```ruby
client.on_message(GrubY::Filters.command("start")) do |app, message|
  message.reply_text("pong")
end

client.on_callback_query do |app, cq|
  cq.answer("ok")
end
```

## Handlers

`GrubY::Handlers` classes are available for `add_handler()`:

- `MessageHandler`, `EditedMessageHandler`, `DeletedMessagesHandler`
- `BusinessMessageHandler`, `EditedBusinessMessageHandler`, `DeletedBusinessMessagesHandler`
- `BusinessConnectionHandler`, `CallbackQueryHandler`, `ChatBoostHandler`, `ChatJoinRequestHandler`
- `ChatMemberUpdatedHandler`, `ChatMemberHandler`, `ChannelPostHandler`, `EditedChannelPostHandler`
- `ChosenInlineResultHandler`, `InlineQueryHandler`, `PollAnswerHandler`
- `MessageReactionCountHandler`, `MessageReactionHandler`, `PollHandler`
- `RemovedChatBoostHandler`, `WidgetQueryHandler`, `SharedWidgetQueryHandler`
- `BotSubscriptionUpdatedHandler`, `MessageGenerationStoppedHandler`
- `GuestMessageHandler`, `MyChatMemberHandler`
- `PreCheckoutQueryHandler`, `PurchasedPaidMediaHandler`, `ShippingQueryHandler`
- `StoryHandler`, `UserStatusHandler`
- `StartHandler`, `StopHandler`, `ConnectHandler`, `DisconnectHandler`
- `ErrorHandler`, `ManagedBotUpdatedHandler`, `RawUpdateHandler`

Example:

```ruby
handler = GrubY::Handlers::MessageHandler.new(proc { |app, message| message.reply_text("hi") })
client.add_handler(handler)
```

## Update Filters

Ruby `GrubY::Filters` now supports:

- `create(func:, name:, **kwargs)` custom filter creator
- Boolean composition: `&`, `|`, `~`
- Update filters: `all`, `me`, `bot`, `sender_chat`, `incoming`, `outgoing`
- Content filters: `text`, `reply`, `forwarded`, `caption`, `audio`, `document`, `photo`, `sticker`, `animation`, `video`, `voice`, `video_note`, `contact`, `location`, `venue`, `web_page`, `poll`, `dice`, `quote`, `media_spoiler`, `story`, `media_group`
- Chat filters: `private`, `group`, `channel`, `direct`, `forum`
- Service/media filters: `service`, `media`, plus specific service keys (`new_chat_members`, `pinned_message`, `video_chat_started`, etc.)
- Parameterized filters: `command(...)`, `regex(...)`, `user(...)`, `chat(...)`, `topic(...)`

Example:

```ruby
f = GrubY::Filters.command(%w[start help]) & GrubY::Filters.private
client.on_message(f) { |app, msg| msg.reply_text("ok") }
```

## Steps to Setup TDJSON:

1. Push a tag (example: `v0.2.1`) or manually run the `Release TDJSON` workflow.
2. Download the zip for your OS from the GitHub Release assets:
   - `tdjson-linux-x64.zip`
   - `tdjson-macos-x64.zip`
   - `tdjson-windows-x64.zip`
3. Extract and copy them into the repo:
   - `Linux: vendor/tdlib/linux/libtdjson.so`
   - `macOS: vendor/tdlib/macos/libtdjson.dylib`
   - `Windows: vendor/tdlib/windows/tdjson.dll`
4. Optional: Set `TDJSON_PATH` if you want to use a custom path.

Note: `GrubY::TDLib::Native` now also auto-detects from `vendor/tdlib/...` paths.

## Examples:

- `example/bot.rb`
- `example/generate_user_session.rb`
- `example/tdlib.rb`
- `example/userbot.rb` (phone/QR login)
