part of xml_stream;

class XmlStreamer {
  static const EMPTY = '';
  
  String raw;
  StreamController<XmlEvent> _controller;
  
  bool _shutdown = false;
  
  XmlStreamer(this.raw);
  
  Stream<XmlEvent> read() {
    _controller = new StreamController<XmlEvent>();
    
    XmlEvent event = createAndAddXmlEvent(XmlState.StartDocument);
    String prev;
    var chars_raw = this.raw.split("");
    for (var ch in chars_raw) {
      switch(ch) {
        case XmlChar.LT:
          if (event.state != null && event.value.trim().isNotEmpty) {
            _controller.add(event);
          }
          event = createXmlEvent(XmlState.Open);
          break;
        case XmlChar.GT:
          _controller.add(event);
          event = createXmlEvent(XmlState.Text);
          break;
        case XmlChar.SLASH:
          if (event.state == XmlState.Open) { 
            event = createXmlEvent(XmlState.Closed);
          } else {
            event = addCharToValue(event, ch);
          }
          break;
        case XmlChar.SPACE:
          if (event.state == XmlState.Open && event.value == '!--') {
            event = createXmlEvent(XmlState.Comment);
          } else if (event.state == XmlState.Open || event.state == XmlState.Attribute) {
            _controller.add(event);
            event = createXmlEvent(event.state);
          } else {
            event = addCharToValue(event, ch);
          }
          break;
        case XmlChar.EQUALS:
          var value = event.value;
          if (event.state == XmlState.Open || event.state == XmlState.Attribute) {
            event = createXmlEvent(XmlState.Attribute);
            event.key = value;
          } else {
            event.value = "$value$ch";
          }
          break;
        case XmlChar.DASH:
          if (event.state != XmlState.Comment) {
            event = addCharToValue(event, ch);
          }
          break;
        case XmlChar.QUESTIONMARK:
          event = createXmlEvent(XmlState.Top);
          break;
        case XmlChar.SINGLE_QUOTES:
          break;
        case XmlChar.DOUBLE_QUOTES:
          break;
        case XmlChar.NEWLINE:
          break;
        default:
          event = addCharToValue(event, ch);
      }
      prev = ch;
      if (_shutdown) break;
    }
    event = createAndAddXmlEvent(XmlState.EndDocument);
    return _controller.stream;
  }
  
  XmlEvent addCharToValue(XmlEvent event, String ch) {
    var value = event.value;
    event.value = "$value$ch";
    return event;
  }

  XmlEvent createAndAddXmlEvent(XmlState state) {
    XmlEvent event = createXmlEvent(state);
    _controller.add(event);
    return event;
  }
  
  XmlEvent createXmlEvent(XmlState state) {
    XmlEvent event = new XmlEvent(state);
    event..value=EMPTY
         ..key=EMPTY;
    return event;
  }
  
  void shutdown() { _shutdown = true; }
}
