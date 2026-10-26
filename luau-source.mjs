export function stripLuauComments(source) {
  let out = '', i = 0;
  const longAt = at => source.slice(at).match(/^\[(=*)\[/);
  while (i < source.length) {
    if (source.startsWith('--', i)) {
      const start = i;
      const long = longAt(i + 2);
      if (long) {
        const end = source.indexOf(']' + long[1] + ']', i + 2 + long[0].length);
        if (end < 0) throw new Error('Unterminated long comment');
        i = end + long[1].length + 2;
      } else {
        while (i < source.length && source[i] !== '\n' && source[i] !== '\r') i++;
      }
      out += ' ' + (source.slice(start, i).match(/\r\n|\r|\n/g) || []).join('');
      continue;
    }
    const quote = source[i];
    if (quote === '"' || quote === "'" || quote === '`') {
      const start = i++;
      while (i < source.length) {
        if (source[i] === '\\') { i += 2; continue; }
        if (source[i++] === quote) break;
      }
      out += source.slice(start, i);
      continue;
    }
    const long = source[i] === '[' && longAt(i);
    if (long) {
      const end = source.indexOf(']' + long[1] + ']', i + long[0].length);
      if (end < 0) throw new Error('Unterminated long string');
      const next = end + long[1].length + 2;
      out += source.slice(i, next); i = next;
      continue;
    }
    out += source[i++];
  }
  return out;
}
