require_relative "../lib/gruubY"
require_relative "../config/config"

client = GrubY::Client.new(Config::TOKEN)
gm = client.group_manager

plugin_file = File.join(__dir__, '../plugins/logger.rb')
client.use_plugin(plugin_file)

HELP = <<~TXT
  Commands:
  /start - Boot check
  /help - Show this help message
  /echo <text> - Echo text
  /md <text> - Markdown v2 safe send
  /html <text> - HTML safe send
  /poll - Send sample poll
  /media - Send sample media methods
  /edit - Send and edit a message
  /rich - Send a rich message
  /widget - Send an HTML widget in a private chat
  /sticker <file_id> - Send a sticker by file ID
  /stickerset <name> - Get a sticker set
  /botname - Get the bot name
  /whoami - Show user and chat info
  /warn <user_ID> [reason] - Warn user
  /mute <user_ID> - Mute user
  /unmute <user_ID> - Unmute user
  /ban <user_ID> - Ban user
  /unban <user_ID> - Unban user
  /pin - Pin message
  /unpin - Unpin latest pinned message
  /lock - Lock group
  /unlock - Unlock group
  /reaction - Set reaction on replied message
TXT

client.on(:message, GrubY::Filters.command("start")) do |ctx|
  ctx.reply("GrubY Client started! Use /help for help message.")
end

client.on(:message, GrubY::Filters.command("help")) do |ctx|
  ctx.reply(HELP)
end

client.on(:message, GrubY::Filters.command("echo")) do |ctx|
  text = ctx.command_args.join(" ")
  ctx.reply(text.empty? ? "Usage: /echo good morning" : text)
end

client.on(:message, GrubY::Filters.command("md")) do |ctx|
  text = ctx.command_args.join(" ")
  safe = GrubY::API.escape_markdown_v2(text.empty? ? "markdown_v2 demo" : text)
  client.send_message(ctx.chat_id, "*Safe:* #{safe}", parse_mode: "MarkdownV2")
end

client.on(:message, GrubY::Filters.command("html")) do |ctx|
  text = ctx.command_args.join(" ")
  safe = GrubY::API.escape_html(text.empty? ? "<b>html</b> demo" : text)
  client.send_message(ctx.chat_id, "<b>Safe:</b> #{safe}", parse_mode: "HTML")
end

client.on(:message, GrubY::Filters.command("poll")) do |ctx|
  client.send_poll(
    ctx.chat_id,
    "Pick Stack",
    [
      { text: "Ruby" },
      { text: "Python" },
      { text: "JavaScript" }
    ],
    is_anonymous: false,
    allows_multiple_answers: true
  )
end

client.on(:message, GrubY::Filters.command("media")) do |ctx|
  client.send_chat_action(ctx.chat_id, "typing")
  ctx.reply("Try these API methods from code: send_photo/send_document/send_video/send_animation/send_voice/send_video_note/send_media_group/send_paid_media")
end

client.on(:message, GrubY::Filters.command("edit")) do |ctx|
  sent = ctx.reply("This message will be edited.")
  client.edit_message_text(
    ctx.chat_id,
    sent.fetch("message_id"),
    "Message edited with the Bot API."
  )
end

client.on(:message, GrubY::Filters.command("rich")) do |ctx|
  client.send_rich_message(
    chat_id: ctx.chat_id,
    rich_message: { html: "<p>Rich message sent with GrubY.</p>" }
  )
end

client.on(:message, GrubY::Filters.command("widget")) do |ctx|
  unless ctx.message&.chat&.type == "private"
    ctx.reply("Widgets are supported here only in a private chat with the bot.")
    next
  end

  client.send_widget(
    chat_id: ctx.chat_id,
    html: "<div><p>Hello from a Telegram widget.</p></div>",
    allow_queries: true
  )
end

client.on(:message, GrubY::Filters.command("sticker")) do |ctx|
  file_id = ctx.command_args.first
  if file_id.to_s.empty?
    ctx.reply("Usage: /sticker <file_id>")
    next
  end

  client.send_sticker(ctx.chat_id, file_id)
end

client.on(:message, GrubY::Filters.command("stickerset")) do |ctx|
  name = ctx.command_args.first
  if name.to_s.empty?
    ctx.reply("Usage: /stickerset <sticker_set_name>")
    next
  end

  sticker_set = client.get_sticker_set(name: name)
  ctx.reply("#{sticker_set["title"]}: #{sticker_set["stickers"].length} stickers")
end

client.on(:message, GrubY::Filters.command("botname")) do |ctx|
  result = client.get_my_name
  ctx.reply(result["name"].to_s.empty? ? "Bot name is not set." : result["name"])
end

client.on_channel_post do |_app, post|
  puts "Channel post #{post.message_id} received in #{post.chat&.id}"
end

client.on_edited_channel_post do |_app, post|
  puts "Channel post #{post.message_id} was edited"
end

client.on_guest_message do |_app, message|
  puts "Guest message #{message.message_id} received (query=#{message.guest_query_id})"
  client.answer_guest_query(
    guest_query_id: message.guest_query_id,
    result: {
      type: "article",
      id: "guest-reply",
      title: "Thanks",
      input_message_content: { message_text: "Thanks for your message." }
    }
  )
end

client.on_poll_answer do |_app, answer|
  puts "Poll answer received for poll #{answer.poll_id}"
end

client.on_chat_member do |_app, member_update|
  puts "Chat member status changed in #{member_update.chat&.id}"
end

client.on_my_chat_member do |_app, member_update|
  puts "Bot status changed in #{member_update.chat&.id}"
end

client.on_widget_query do |_app, query|
  puts "Widget query received: #{query.id}"
  client.answer_widget_query(widget_query_id: query.id, data: "received")
end

client.on_shared_widget_query do |_app, query|
  puts "Shared widget query received: #{query.id}"
end

client.on_removed_chat_boost do |_app, boost|
  puts "A boost was removed from #{boost.chat&.id}"
end

client.on_bot_subscription_updated do |_app, subscription|
  puts "Subscription update received: #{subscription.to_h}"
end

client.on_message_generation_stopped do |_app, stopped|
  puts "Message generation stopped: #{stopped.to_h}"
end

client.on_managed_bot do |_app, managed_bot|
  puts "Managed bot update received: #{managed_bot.to_h}"
end

client.on(:message, GrubY::Filters.command("whoami")) do |ctx|
  user = ctx.user
  chat = ctx.message&.chat
  text = "user_id=#{user&.id} username=@#{user&.username} chat_id=#{chat&.id} chat_type=#{chat&.type}"
  ctx.reply(text)
end

client.on(:message, GrubY::Filters.command("warn")) do |ctx|
  user_id = ctx.command_args[0]&.to_i
  reason = ctx.command_args[1..]&.join(" ")
  if user_id.nil? || user_id.zero?
    ctx.reply("Usage: /warn <user_ID> [reason]")
    next
  end

  result = gm.enforce_warns(ctx.chat_id, user_id, reason: reason)
  if result[:action] == :kick
    ctx.reply("User #{user_id} has been kicked. Reason: Warning limit exceeded.")
  else
    ctx.reply("Warned #{user_id}. #{result[:warns]}/#{result[:limit]}")
  end
end

client.on(:message, GrubY::Filters.command("mute")) do |ctx|
  user_id = ctx.command_args[0]&.to_i
  next ctx.reply("Usage: /mute <user_ID>") if user_id.nil? || user_id.zero?

  gm.mute(ctx.chat_id, user_id)
  ctx.reply("Muted #{user_id}")
end

client.on(:message, GrubY::Filters.command("unmute")) do |ctx|
  user_id = ctx.command_args[0]&.to_i
  next ctx.reply("Usage: /unmute <user_ID>") if user_id.nil? || user_id.zero?

  gm.unmute(ctx.chat_id, user_id)
  ctx.reply("Unmuted #{user_id}")
end

client.on(:message, GrubY::Filters.command("ban")) do |ctx|
  user_id = ctx.command_args[0]&.to_i
  next ctx.reply("Usage: /ban <user_ID>") if user_id.nil? || user_id.zero?

  gm.ban(ctx.chat_id, user_id)
  ctx.reply("Banned #{user_id}")
end

client.on(:message, GrubY::Filters.command("unban")) do |ctx|
  user_id = ctx.command_args[0]&.to_i
  next ctx.reply("Usage: /unban <user_ID>") if user_id.nil? || user_id.zero?

  gm.unban(ctx.chat_id, user_id, only_if_banned: true)
  ctx.reply("Unbanned #{user_id}")
end

client.on(:message, GrubY::Filters.command("pin")) do |ctx|
  gm.pin(ctx.chat_id, ctx.message.message_id)
  ctx.reply("Pinned this message.")
end

client.on(:message, GrubY::Filters.command("unpin")) do |ctx|
  gm.unpin(ctx.chat_id)
  ctx.reply("Unpinned latest message.")
end

client.on(:message, GrubY::Filters.command("lock")) do |ctx|
  gm.lock(ctx.chat_id)
  ctx.reply("Group locked!")
end

client.on(:message, GrubY::Filters.command("unlock")) do |ctx|
  gm.unlock(ctx.chat_id)
  ctx.reply("Group unlocked!")
end

client.on(:message, GrubY::Filters.command("reaction")) do |ctx|
  message_id = ctx.message.message_id
  client.send_reaction(ctx.chat_id, message_id, reaction: [{ type: "emoji", emoji: "\u{1F525}" }])
  ctx.reply("Reaction sent.")
end

client.on(:message, GrubY::Filters.regex(/hello/i)) do |ctx|
  ctx.reply("Hello world from GrubY!")
end

client.run
