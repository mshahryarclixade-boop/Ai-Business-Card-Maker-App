/// English strings. Add other locales as sibling maps and pick one in
/// [Trans.tr] when the app gains localization.
abstract final class AppStrings {
  static const Map<String, String> en = {
    // Credit gate
    'credit_gate_limit_reached_title': 'Limit reached',
    'credit_gate_limit_reached_message':
        "You've used all the credits in your current plan. They refill at "
        'the start of your next billing period.',
    'credit_gate_ok': 'OK',
    'credit_gate_out_of_credits_title': 'Out of credits',
    'credit_gate_out_of_credits_message':
        'Upgrade to Pro to keep creating business cards.',
    'credit_gate_upgrade': 'Upgrade',
    'credit_gate_not_now': 'Not now',

    // Connection dialog
    'connection_interrupted_title': 'Connection interrupted',
    'connection_interrupted_message':
        'Your connection dropped during the purchase. Please check your '
        'internet and try again.',

    // Paywall / purchases
    'paywall_controller_try_again_message': 'Please try again in a moment.',
    'paywall_controller_store_unavailable_title': 'Store unavailable',
    'paywall_controller_store_unavailable_message':
        'The store is not available right now. Please check your connection '
        'and try again.',
    'paywall_controller_purchase_restored_title': 'Purchase restored',
    'paywall_controller_purchase_restored_message':
        'Your subscription is active again.',
    'paywall_controller_purchase_pending_title': 'Purchase pending',
    'paywall_controller_purchase_pending_message':
        'Your purchase is waiting for approval. Pro unlocks once it goes '
        'through.',
    'paywall_controller_purchase_failed_title': 'Purchase failed',
    'paywall_controller_restore_failed_title': 'Restore failed',
    'paywall_controller_nothing_to_restore_title': 'Nothing to restore',
    'paywall_controller_nothing_to_restore_message':
        'No active subscription was found for this account.',
    'paywall_controller_already_owned_title': 'Already subscribed',
    'paywall_controller_already_owned_message':
        "You already own this subscription, but we couldn't confirm it "
        'right now. Try Restore Purchase.',
  };
}
