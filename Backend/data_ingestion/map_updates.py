def send_authority_map_update(reason):
    """Send a silent event so authority maps reload only after actual changes."""
    import threading

    def _send():
        try:
            import firebase_admin
            from firebase_admin import messaging
            from accounts.models import DeviceToken

            if not firebase_admin._apps:
                return

            tokens = list(
                DeviceToken.objects
                .filter(user__role__iexact='AUTHORITY')
                .values_list('token', flat=True)
            )
            for i in range(0, len(tokens), 500):
                messaging.send_each_for_multicast(
                    messaging.MulticastMessage(
                        tokens=tokens[i:i + 500],
                        data={'type': 'MAP_DATA_UPDATED', 'reason': str(reason)},
                        android=messaging.AndroidConfig(priority='high'),
                        apns=messaging.APNSConfig(
                            headers={'apns-priority': '5'},
                            payload=messaging.APNSPayload(
                                aps=messaging.Aps(content_available=True),
                            ),
                        ),
                    )
                )
        except Exception as exc:
            print(f"Authority map update signal skipped: {exc}")

    threading.Thread(target=_send, daemon=True).start()
