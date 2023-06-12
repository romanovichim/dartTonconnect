import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart';
import 'package:universal_html/html.dart';

import 'package:darttonconnect/exceptions.dart';
import 'package:darttonconnect/logger.dart';
import 'package:darttonconnect/storage/interface.dart';

class BridgeGateway {
  static const String ssePath = 'events';
  static const String postPath = 'message';
  static const int defaultTtl = 300;

  late Completer<bool> resolve;
  EventSource? _eventSource;
  bool _isClosed = false;

  final IStorage _storage;
  final String _bridgeUrl;
  final String _sessionId;
  final Function _listener;
  final Function _errorsListener;

  BridgeGateway(this._storage, this._bridgeUrl, this._sessionId, this._listener,
      this._errorsListener) {
    resolve = Completer();
  }

  Future<bool> registerSession() async {
    if (_isClosed) {
      return false;
    }

    final bridgeBase = _bridgeUrl;
    var bridgeUrl = '$bridgeBase/$ssePath?client_id=$_sessionId';

    final lastEventId = await _storage.getItem(key: IStorage.keyLastEventId);
    if (lastEventId != null) {
      bridgeUrl += '&last_event_id=$lastEventId';
    }

    logger.d('Bridge url -> $bridgeUrl');

    if (_eventSource != null) {
      _eventSource!.close();
    }

    _eventSource = EventSource(bridgeUrl);

    _eventSource!.onError.listen(_errorsHandler);
    _eventSource!.onOpen.listen((_) {
      resolve.complete(true);
    });

    _eventSource!.onMessage.listen((event) async {
      try {
        logger.d(event);
        await _messagesHandler(event);
      } on TimeoutException {
        logger.e('Bridge error -> TimeoutError');
      } on ClientException {
        logger.e('Bridge error -> ClientConnectionError');
      } catch (e) {
        logger.e('Bridge error -> Unknown');
      }
    });

    return await resolve.future;
  }

  Future<void> send(String request, String receiverPublicKey, String topic,
      {int? ttl}) async {
    final bridgeBase = _bridgeUrl;

    var bridgeUrl = '$bridgeBase/$postPath?client_id=$_sessionId';
    final ttlValue = ttl ?? defaultTtl;
    bridgeUrl += '&to=$receiverPublicKey&ttl=$ttlValue&topic=$topic';

    final xhr = HttpRequest();
    xhr.open('POST', bridgeUrl);
    xhr.setRequestHeader('Content-Type', 'application/json; charset=utf-8');
    xhr.send(request);
  }

  void pause() {
    _eventSource!.close();
  }

  Future<void> unpause() async {
    await registerSession();
  }

  Future<void> close() async {
    _isClosed = true;
    _eventSource!.close();
  }

  void _errorsHandler(Event event) {
    if (!_isClosed) {
      switch (_eventSource!.readyState) {
        case EventSource.CLOSED:
          logger.e('Bridge error -> CLOSED');
          break;
        case EventSource.CONNECTING:
          logger.e('Bridge error -> CONNECTING');
          break;
        default:
          _errorsListener();
      }
    }
  }

  Future<void> _messagesHandler(MessageEvent event) async {
    await _storage.setItem(
        key: IStorage.keyLastEventId, value: event.lastEventId);

    if (!_isClosed) {
      try {
        final data = jsonDecode(event.data);
        await _listener(data);
      } catch (e) {
        throw TonConnectError('Bridge listener failed');
      }
    }
  }
}
