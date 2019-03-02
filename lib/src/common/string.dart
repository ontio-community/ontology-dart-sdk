import 'dart:math';

String substr(String str, int start, int len) {
  assert(len >= 0);
  if (len == 0) return '';

  start = start > 0 ? start : str.length + start;
  start = min(start, str.length - 1);
  var end = start + len;
  end = min(end, str.length - 1);
  return str.substring(start, end);
}
