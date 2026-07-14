/// Single source of truth mapping a notification (type + payload keys)
/// to the screen it should open — used by BOTH the in-app bell
/// (notifications_screen.dart) and push-notification taps
/// (push_service.dart), so the two entry points can never route
/// differently. The send-notification edge function mirrors these keys
/// into the FCM data payload (type / mk_code / request_id).
library;

String? notificationRoute(
  String type, {
  String? mkCode,
  String? requestId,
}) {
  final mk = (mkCode != null && mkCode.isNotEmpty) ? mkCode : null;
  final req = (requestId != null && requestId.isNotEmpty) ? requestId : null;

  // Research flow: anything carrying a request id lands on the request.
  if (req != null) return '/research/$req';

  if (mk == null) return null;

  // Discussion touch points land on the thread itself; chart-level
  // outcomes (report actioned/dismissed) land on the chart.
  const discussionTypes = {
    'comment_reply',
    'chart_comment',
    'comment_held',
    'comment_removed',
    'comment_restored',
  };
  return discussionTypes.contains(type)
      ? '/mahakosh/chart/$mk/discussion'
      : '/mahakosh/chart/$mk';
}
