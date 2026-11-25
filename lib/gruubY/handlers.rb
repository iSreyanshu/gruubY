module GrubY
  module Handlers
    class BaseHandler
      attr_reader :callback, :filters, :group, :exceptions

      def initialize(callback = nil, filters: nil, group: 0, exceptions: nil, &block)
        @callback = callback || block
        @filters = filters
        @group = group.to_i
        @exceptions = exceptions
      end

      def event
        raise NotImplementedError
      end

      def extract(ctx)
        ctx
      end

      def client_only?
        false
      end
    end

    class MessageHandler < BaseHandler
      def event = :message
      def extract(ctx) = ctx.message
    end

    class EditedMessageHandler < BaseHandler
      def event = :edited_message
      def extract(ctx) = ctx.edited_message
    end

    class ChannelPostHandler < BaseHandler
      def event = :channel_post
      def extract(ctx) = ctx.channel_post
    end

    class EditedChannelPostHandler < BaseHandler
      def event = :edited_channel_post
      def extract(ctx) = ctx.edited_channel_post
    end

    class DeletedMessagesHandler < BaseHandler
      def event = :deleted_messages
      def extract(ctx) = ctx.deleted_messages
    end

    class BusinessMessageHandler < BaseHandler
      def event = :business_message
      def extract(ctx) = ctx.business_message
    end

    class EditedBusinessMessageHandler < BaseHandler
      def event = :edited_business_message
      def extract(ctx) = ctx.edited_business_message
    end

    class GuestMessageHandler < BaseHandler
      def event = :guest_message
      def extract(ctx) = ctx.guest_message
    end

    class DeletedBusinessMessagesHandler < BaseHandler
      def event = :deleted_business_messages
      def extract(ctx) = ctx.deleted_business_messages
    end

    class BusinessConnectionHandler < BaseHandler
      def event = :business_connection
      def extract(ctx) = ctx.business_connection
    end

    class CallbackQueryHandler < BaseHandler
      def event = :callback_query
      def extract(ctx) = ctx.callback_query
    end

    class ChatBoostHandler < BaseHandler
      def event = :chat_boost
      def extract(ctx) = ctx.chat_boost
    end

    class ChatJoinRequestHandler < BaseHandler
      def event = :chat_join_request
      def extract(ctx) = ctx.chat_join_request
    end

    class ChatMemberUpdatedHandler < BaseHandler
      def event = :chat_member_updated
      def extract(ctx) = ctx.chat_member_updated
    end

    class ChosenInlineResultHandler < BaseHandler
      def event = :chosen_inline_result
      def extract(ctx) = ctx.chosen_inline_result
    end

    class InlineQueryHandler < BaseHandler
      def event = :inline_query
      def extract(ctx) = ctx.inline_query
    end

    class MessageReactionCountHandler < BaseHandler
      def event = :message_reaction_count
      def extract(ctx) = ctx.message_reaction_count
    end

    class MessageReactionHandler < BaseHandler
      def event = :message_reaction
      def extract(ctx) = ctx.message_reaction
    end

    class PollHandler < BaseHandler
      def event = :poll
      def extract(ctx) = ctx.poll_update
    end

    class PollAnswerHandler < BaseHandler
      def event = :poll_answer
      def extract(ctx) = ctx.poll_answer
    end

    class ChatMemberHandler < BaseHandler
      def event = :chat_member
      def extract(ctx) = ctx.chat_member_updated
    end

    class MyChatMemberHandler < BaseHandler
      def event = :my_chat_member
      def extract(ctx) = ctx.my_chat_member
    end

    class RemovedChatBoostHandler < BaseHandler
      def event = :removed_chat_boost
      def extract(ctx) = ctx.removed_chat_boost
    end

    class WidgetQueryHandler < BaseHandler
      def event = :widget_query
      def extract(ctx) = ctx.widget_query
    end

    class SharedWidgetQueryHandler < BaseHandler
      def event = :shared_widget_query
      def extract(ctx) = ctx.shared_widget_query
    end

    class BotSubscriptionUpdatedHandler < BaseHandler
      def event = :bot_subscription_updated
      def extract(ctx) = ctx.bot_subscription_updated
    end

    class MessageGenerationStoppedHandler < BaseHandler
      def event = :message_generation_stopped
      def extract(ctx) = ctx.message_generation_stopped
    end

    class PreCheckoutQueryHandler < BaseHandler
      def event = :pre_checkout_query
      def extract(ctx) = ctx.pre_checkout_query
    end

    class PurchasedPaidMediaHandler < BaseHandler
      def event = :purchased_paid_media
      def extract(ctx) = ctx.purchased_paid_media
    end

    class ShippingQueryHandler < BaseHandler
      def event = :shipping_query
      def extract(ctx) = ctx.shipping_query
    end

    class StoryHandler < BaseHandler
      def event = :story
      def extract(ctx) = ctx.story_update
    end

    class UserStatusHandler < BaseHandler
      def event = :user_status
      def extract(ctx) = ctx.user_status
    end

    class StartHandler < BaseHandler
      def event = :start
      def extract(_ctx) = nil
      def client_only? = true
    end

    class StopHandler < BaseHandler
      def event = :stop
      def extract(_ctx) = nil
      def client_only? = true
    end

    class ConnectHandler < BaseHandler
      def event = :connect
      def extract(_ctx) = nil
      def client_only? = true
    end

    class DisconnectHandler < BaseHandler
      def event = :disconnect
      def extract(_ctx) = nil
      def client_only? = true
    end

    class ErrorHandler < BaseHandler
      def event = :error
      def extract(ctx) = ctx.error_payload
    end

    class ManagedBotUpdatedHandler < BaseHandler
      def event = :managed_bot
      def extract(ctx) = ctx.managed_bot_updated
    end

    class RawUpdateHandler < BaseHandler
      def event = :raw_update
      def extract(ctx) = ctx.update
    end
  end
end
