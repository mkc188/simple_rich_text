library simple_rich_text;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:meta/meta.dart';
import 'package:simple_navigation/simple_navigation.dart';
import 'package:url_launcher/url_launcher.dart';

const Map<String, int> colorMap = {
  'aqua': 0x00FFFF,
  'black': 0x000000,
  'blue': 0x0000FF,
  'brown': 0x9A6324,
  'cream': 0xFFFDD0,
  'cyan': 0x46f0f0,
  'green': 0x00FF00,
  'gray': 0x808080,
  'grey': 0x808080,
  'mint': 0xAAFFC3,
  'lavender': 0xE6BEFF,
  'new': 0xFFFF00,
  'olive': 0x808000,
  'orange': 0xFFA500,
  'pink': 0xFFE1E6,
  'purple': 0x800080,
  'red': 0xFF0000,
  'silver': 0xC0C0C0,
  'white': 0xFFFFFF,
  'yellow': 0xFFFF00
};

Color parseColor(String color) {
//  print("parseColor: $color");
  var v = colorMap[color];
  if (v == null) {
    return Colors.red;
  } else {
//    return Color(v);
//    return Colors.green;
//    int n = Color(v);
    Color out = Color((0xff << 24) | v);
//    print("parseColor: $color => $out");
    return out;
  }
}

/// Widget that renders a string with sub-string highlighting.
class SimpleRichText extends StatelessWidget {
  SimpleRichText({
    @required this.text,
    this.chars,
    this.context,
    this.fussy,
    this.log,
    this.style = const TextStyle(),
    this.textAlign,
    this.textOverflow,
    this.maxLines,
  });

  final String chars;

  /// For navigation
  final BuildContext context;

  /// Throw exception if tags not closed (e.g., "this is *bold" because no closing * character)
  final bool fussy;

  /// Pass in true for debugging/logging/trace
  final bool log;

  /// The {TextStyle} of the {SimpleRichText.text} that isn't highlighted.
  final TextStyle style;

  /// The String to be displayed using rich text.
  final String text;

  /// The {TextStyle} of the {SimpleRichText.term}s found.
//  final TextStyle textStyleHighlight;

  /// Text align
  final TextAlign textAlign;

  /// Text Overflow
  final TextOverflow textOverflow;

  /// Max lines
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    if (text == null || text.isEmpty) {
      return Text('');
    } else {
      //print('text: $text');
      List<InlineSpan> children = [];

      Set set = Set();

      bool containsNewLine = text.contains(r'\n');
      print('Contains new line: $containsNewLine');
      List<String> linesList = List();
      if (containsNewLine) {
        linesList = text.split(r'\n');
        print("lines=${linesList.length}: $linesList");
      } else {
        linesList.add(text);
      }
      // Apply modifications into all lines
      for (int k = 0; k < linesList.length; k++) {
        print('Line ${k + 1}: ${linesList[k]}');
        // split into array
        List<String> spanList = linesList[k].split(RegExp(chars ?? r"[*~_\\]"));
        print("len=${spanList.length}: $spanList");

        if (spanList.length == 1) {
          print("trivial");
          if (style == null) {
            children.add(TextSpan(text: ''));
            // If no last line:
            if (k < linesList.length - 1) children.add(TextSpan(text: '\n'));
          } else {
            children.add(TextSpan(text: linesList[k], style: style));
            // If no last line:
            if (k < linesList.length - 1) children.add(TextSpan(text: '\n'));
          }
        } else {
          int i = 0;
          bool acceptNext = true;
          String cmd;

          void wrap(String v) {
            print("wrap: $v set=$set");

            Map<String, String> map = {};

            if (cmd != null) {
              var pairs = cmd.split(';');
              for (var pair in pairs) {
                var a = pair.split(':');
                if (a.length == 2) {
                  map[a[0].trim()] = a[1].trim();
                } else {
                  throw "attribute value is missing a value (e.g., you passed {key} but not {key:value}";
                }
              }
              if (log ?? false) print("attributes: $map");
            }

            // TextDecorationStyle "values" is ignored
            TextDecorationStyle _textDecorationStyle;
            if (map.containsKey('decorationStyle')) {
              if (map['decorationStyle'] == 'dashed')
                _textDecorationStyle = TextDecorationStyle.dashed;
              if (map['decorationStyle'] == 'double')
                _textDecorationStyle = TextDecorationStyle.double;
              if (map['decorationStyle'] == 'dotted')
                _textDecorationStyle = TextDecorationStyle.dotted;
              if (map['decorationStyle'] == 'solid')
                _textDecorationStyle = TextDecorationStyle.solid;
              if (map['decorationStyle'] == 'wavy')
                _textDecorationStyle = TextDecorationStyle.wavy;
            }

            TextStyle ts;
            ts = style.copyWith(
              color: map.containsKey('color')
                  ? parseColor(map['color'])
                  : style.color,
              decoration: set.contains('_')
                  ? TextDecoration.underline
                  : TextDecoration.none,
              // fontStyle:
              // set.contains('/') ? FontStyle.italic : FontStyle.normal,
              fontWeight:
              set.contains('*') ? FontWeight.w600 : FontWeight.normal,
              fontSize: map.containsKey('fontSize')
                  ? double.parse(map['fontSize'])
                  : style.fontSize,
              fontFamily: map.containsKey('fontFamily')
                  ? '${map['fontFamily']}'
                  : style.fontFamily,
              backgroundColor: map.containsKey('backgroundColor')
                  ? parseColor(map['backgroundColor'])
                  : style.backgroundColor,
              decorationColor: map.containsKey('decorationColor')
                  ? parseColor(map['decorationColor'])
                  : style.decorationColor,
              decorationStyle: _textDecorationStyle ?? style.decorationStyle,
              decorationThickness: map.containsKey('decorationThickness')
                  ? double.parse(map['decorationThickness'])
                  : style.decorationThickness,
              height: map.containsKey('height')
                  ? double.parse(map['height'])
                  : style.height,
              letterSpacing: map.containsKey('letterSpacing')
                  ? double.parse(map['letterSpacing'])
                  : style.letterSpacing,
              wordSpacing: map.containsKey('wordSpacing')
                  ? double.parse(map['wordSpacing'])
                  : style.wordSpacing,
            );

            if (map.containsKey('pop') ||
                map.containsKey('push') ||
                map.containsKey('repl') ||
                map.containsKey('http')) {
//            print("BBB cmd=$cmd");
//          GestureDetector
//        children.add(WidgetSpan(child: Text('****')));
//          children.add(WidgetSpan(
//              child: GestureDetector(
//            child: Text('CLICK'),
//            onTap: () async {
//              //print("TAPPED");
//            },
//          )));

              assert(context != null, 'must pass context if using route links');

              onTapNew(String caption, Map m) {
                assert(m != null);
                if (map.containsKey('push')) {
                  String v = map['push'];
                  return () {
                    if (log ?? false) print("TAP: PUSH: $caption => /$v");
                    assert(v != null);
//                  Navigator.pushNamed(context, '/$v');
                    Nav.push('/$v');
                  };
                } else if (map.containsKey('repl')) {
                  String v = map['repl'];
                  return () {
                    if (log ?? false) print("TAP: POP&PUSH: $caption => /$v");
                    assert(v != null);
//                  Navigator.popAndPushNamed(context, '/$v');
                    Nav.repl('/$v');
                  };
                } else if (map.containsKey('http')) {
                  String v = map['http'];
                  return () async {
                    print("TAP: HTTP: $caption => /$v");
                    assert(v != null);
                    try {
                      await launch('https://$v', forceSafariVC: false, forceWebView: false);
                    } catch (e) {
                      print('Could not launch http://$v: $e');
                      try {
                        await launch('http://$v', forceSafariVC: false, forceWebView: false);
                      } catch (e) {
                        print('Could not launch http://$v: $e');
                      }
                    }
                  }; // TODO add possibility of tel, mailto, sms, whats,...?
                } else {
                  return () {
                    if (log ?? false) print("TAP: $caption => pop");
//                  Navigator.pop(context);
                    Nav.pop();
                  };
                }
              }

              children.add(TextSpan(
                  text: v,
                  // Beware!  This class is only safe because the TapGestureRecognizer is not given a deadline and therefore never allocates any resources.
                  // In any other situation -- setting a deadline, using any of the less trivial recognizers, etc -- you would have to manage the gesture recognizer's lifetime
                  // and call dispose() when the TextSpan was no longer being rendered.
                  // Since TextSpan itself is @immutable, this means that you would have to manage the recognizer from outside
                  // the TextSpan, e.g. in the State of a stateful widget that then hands the recognizer to the TextSpan.
                  recognizer: TapGestureRecognizer()..onTap = onTapNew(v, map),
                  style: ts));
            } else {
              children.add(TextSpan(text: v, style: ts));
            }
          }

          void toggle(String m) {
            if (m == r'\') {
              String c = linesList[k].substring(i + 1, i + 2);
              print("quote: i=$i: $c");
              wrap(c);
              acceptNext = false;
            } else {
              if (acceptNext) {
                if (set.contains(m)) {
                  print("REM: $m");
                  set.remove(m);
                } else {
                  print("ADD: $m");
                  set.add(m);
                }
              }

              acceptNext = true;
            }
          }

          for (var v in spanList) {
            print("========== $v ==========");
            cmd = null; //TRY
            if (v.isEmpty) {
              if (i < linesList[k].length) {
                String m = linesList[k].substring(i, i + 1);
                toggle(m);
                i++;
              }
            } else {
              int adv = v.length;
              if (v[0] == '{') {
                if (log ?? false) print("link: $v");
                int close = v.indexOf('}');
                if (close > 0) {
                  cmd = v.substring(1, close);
                  if (log ?? false) print("AAA cmd=$cmd");
                  v = v.substring(close + 1);
                  print("remaining: $v");
                }
              }
              wrap(v);
              i += adv;
              if (i < linesList[k].length) {
                String m = linesList[k].substring(i, i + 1);
                print("*** format: $m");
                toggle(m);
                i++;
              }
            }
          }

          if ((fussy ?? false) && set.isNotEmpty) {
            throw 'simple_rich_text: not closed: $set'; //TODO: throw real error?
          }

          // If no last line:
          if (k < linesList.length - 1) children.add(TextSpan(text: '\n'));
        }
      }
      return RichText(
        text: TextSpan(children: children),
        textAlign: this.textAlign ?? TextAlign.start,
        overflow: this.textOverflow ?? TextOverflow.clip,
        maxLines: this.maxLines ?? null,
      );
    }
  }
}

