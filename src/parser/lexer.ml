(**
 * Copyright (c) 2013-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the "flow" directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 *
 *)


open Token
open Lex_env

let lexeme = Sedlexing.Utf8.lexeme

let letter = [%sedlex.regexp? 'a'..'z' | 'A'..'Z' | '_' | '$']
let digit = [%sedlex.regexp? '0'..'9']
let decintlit = [%sedlex.regexp? '0' | ('1'..'9', Star digit)] (* DecimalIntegerLiteral *)
let alphanumeric = [%sedlex.regexp? digit | letter]
let word = [%sedlex.regexp? letter, Star alphanumeric]

let hex_digit = [%sedlex.regexp? digit | 'a'..'f' | 'A'..'F']
let non_hex_letter = [%sedlex.regexp? 'g'..'z' | 'G'..'Z' | '_' | '$']

(* Different ways you can write a number *)
let binnumber = [%sedlex.regexp? '0', ('B' | 'b'), Plus ('0' | '1')]
let octnumber = [%sedlex.regexp? '0', ('O' | 'o'), Plus ('0'..'7')]
let legacyoctnumber = [%sedlex.regexp? '0', Plus ('0'..'7')]
let hexnumber = [%sedlex.regexp? '0', ('X' | 'x'), Plus hex_digit]
let scinumber = [%sedlex.regexp?
  ((decintlit, Opt ('.', Star digit)) | ('.', Plus digit)),
  ('e' | 'E'), Opt ('-' | '+'), Plus digit
]
let wholenumber = [%sedlex.regexp? Plus digit, Opt '.']
let floatnumber = [%sedlex.regexp? Star digit, '.', Plus digit]

(* 2-8 alphanumeric characters. I could match them directly, but this leads to
 * ~5k more lines of generated lexer
let htmlentity = "quot" | "amp" | "apos" | "lt" | "gt" | "nbsp" | "iexcl"
  | "cent" | "pound" | "curren" | "yen" | "brvbar" | "sect" | "uml" | "copy"
  | "ordf" | "laquo" | "not" | "shy" | "reg" | "macr" | "deg" | "plusmn"
  | "sup2" | "sup3" | "acute" | "micro" | "para" | "middot" | "cedil" | "sup1"
  | "ordm" | "raquo" | "frac14" | "frac12" | "frac34" | "iquest" | "Agrave"
  | "Aacute" | "Acirc" | "Atilde" | "Auml" | "Aring" | "AElig" | "Ccedil"
  | "Egrave" | "Eacute" | "Ecirc" | "Euml" | "Igrave" | "Iacute" | "Icirc"
  | "Iuml" | "ETH" | "Ntilde" | "Ograve" | "Oacute" | "Ocirc" | "Otilde"
  | "Ouml" | "times" | "Oslash" | "Ugrave" | "Uacute" | "Ucirc" | "Uuml"
  | "Yacute" | "THORN" | "szlig" | "agrave" | "aacute" | "acirc" | "atilde"
  | "auml" | "aring" | "aelig" | "ccedil" | "egrave" | "eacute" | "ecirc"
  | "euml" | "igrave" | "iacute" | "icirc" | "iuml" | "eth" | "ntilde"
  | "ograve" | "oacute" | "ocirc" | "otilde" | "ouml" | "divide" | "oslash"
  | "ugrave" | "uacute" | "ucirc" | "uuml" | "yacute" | "thorn" | "yuml"
  | "OElig" | "oelig" | "Scaron" | "scaron" | "Yuml" | "fnof" | "circ" | "tilde"
  | "Alpha" | "Beta" | "Gamma" | "Delta" | "Epsilon" | "Zeta" | "Eta" | "Theta"
  | "Iota" | "Kappa" | "Lambda" | "Mu" | "Nu" | "Xi" | "Omicron" | "Pi" | "Rho"
  | "Sigma" | "Tau" | "Upsilon" | "Phi" | "Chi" | "Psi" | "Omega" | "alpha"
  | "beta" | "gamma" | "delta" | "epsilon" | "zeta" | "eta" | "theta" | "iota"
  | "kappa" | "lambda" | "mu" | "nu" | "xi" | "omicron" | "pi" | "rho"
  | "sigmaf" | "sigma" | "tau" | "upsilon" | "phi" | "chi" | "psi" | "omega"
  | "thetasym" | "upsih" | "piv" | "ensp" | "emsp" | "thinsp" | "zwnj" | "zwj"
  | "lrm" | "rlm" | "ndash" | "mdash" | "lsquo" | "rsquo" | "sbquo" | "ldquo"
  | "rdquo" | "bdquo" | "dagger" | "Dagger" | "bull" | "hellip" | "permil"
  | "prime" | "Prime" | "lsaquo" | "rsaquo" | "oline" | "frasl" | "euro"
  | "image" | "weierp" | "real" | "trade" | "alefsym" | "larr" | "uarr" | "rarr"
  | "darr" | "harr" | "crarr" | "lArr" | "uArr" | "rArr" | "dArr" | "hArr"
  | "forall" | "part" | "exist" | "empty" | "nabla" | "isin" | "notin" | "ni"
  | "prod" | "sum" | "minus" | "lowast" | "radic" | "prop" | "infin" | "ang"
  | "and" | "or" | "cap" | "cup" | "'int'" | "there4" | "sim" | "cong" | "asymp"
  | "ne" | "equiv" | "le" | "ge" | "sub" | "sup" | "nsub" | "sube" | "supe"
  | "oplus" | "otimes" | "perp" | "sdot" | "lceil" | "rceil" | "lfloor"
  | "rfloor" | "lang" | "rang" | "loz" | "spades" | "clubs" | "hearts" | "diams"
*)
let htmlentity = [%sedlex.regexp?
  alphanumeric, alphanumeric, Opt alphanumeric, Opt alphanumeric,
  Opt alphanumeric, Opt alphanumeric, Opt alphanumeric, Opt alphanumeric
]

(* http://www.ecma-international.org/ecma-262/6.0/#table-32 *)
let whitespace = [%sedlex.regexp?
  0x0009 | 0x000B | 0x000C | 0x0020 | 0x00A0 | 0xfeff |
  0x1680 | 0x180e | 0x2000 .. 0x200a | 0x202f | 0x205f | 0x3000
]

(* minus sign in front of negative numbers
   (only for types! regular numbers use T_MINUS!) *)
let neg = [%sedlex.regexp? '-', Star whitespace]

let line_terminator_sequence = [%sedlex.regexp? '\n' | '\r' | "\r\n"]

(* TODO: allow \u{} *)
let js_id_start = [%sedlex.regexp? '$' | '_' | id_start]
let js_id_continue = [%sedlex.regexp?
  '$' | '_' | 0x200C | 0x200D | id_continue
]

let loc_of_offsets env start_offset end_offset =
  { Loc.
    source = Lex_env.source env;
    start = { Loc.
      line = Lex_env.line env;
      column = start_offset - Lex_env.bol_offset env;
      offset = start_offset;
    };
    _end = { Loc.
      line = Lex_env.line env;
      column = end_offset - Lex_env.bol_offset env;
      offset = end_offset;
    }
  }

let loc_of_lexbuf env (lexbuf: Sedlexing.lexbuf) =
  let start_offset = Sedlexing.lexeme_start lexbuf in
  let end_offset = Sedlexing.lexeme_end lexbuf in
  loc_of_offsets env start_offset end_offset

let loc_of_curr env (lexbuf: Sedlexing.lexbuf) =
  let curr = Sedlexing.lexeme_end lexbuf in
  loc_of_offsets env curr curr

let get_result_and_clear_state (env, lex_token) =
  let env, state = get_and_clear_state env in
  let lex_loc = match lex_token with
  | T_STRING (loc, _, _, _) -> loc
  | T_JSX_TEXT (loc, _, _) -> loc
  | T_TEMPLATE_PART (loc, _, _) -> loc
  | T_REGEXP (loc, _, _) -> loc
  | _ -> loc_of_lexbuf env env.lex_lb
  in
  env, {
    Lex_result.lex_token;
    lex_loc;
    lex_errors = List.rev state.lex_errors_acc;
    lex_comments = List.rev state.lex_comments_acc;
  }

let lex_error (env: Lex_env.t) loc err: Lex_env.t =
  let lex_errors_acc = (loc, err)::env.lex_state.lex_errors_acc in
  { env with lex_state = { env.lex_state with lex_errors_acc; } }

let unexpected_error (env: Lex_env.t) (loc: Loc.t) value =
  lex_error env loc (Parse_error.UnexpectedToken value)

let unexpected_error_w_suggest (env: Lex_env.t) (loc: Loc.t) value suggest =
  lex_error env loc (Parse_error.UnexpectedTokenWithSuggestion (value, suggest))

let illegal (env: Lex_env.t) (loc: Loc.t) =
  lex_error env loc (Parse_error.UnexpectedToken "ILLEGAL")

let new_line env lexbuf =
  let offset = Sedlexing.lexeme_end lexbuf in
  let lex_bol = { line = Lex_env.line env + 1; offset; } in
  { env with Lex_env.lex_bol }

module FloatOfString : sig
  val float_of_string: string -> float
end = struct
  type t = {
    negative: bool;
    mantissa: int;
    exponent: int;
    decimal_exponent: int option;
    todo: char list;
  }

  exception No_good

  let eat f =
    match f.todo with
    | _::todo -> { f with todo; }
    | _ -> raise No_good

  let start str =
    let todo = ref [] in
    String.iter (fun c -> todo := c::(!todo)) str;
    {
      negative = false;
      mantissa = 0;
      exponent = 0;
      decimal_exponent = None;
      todo = List.rev (!todo);
    }

  let parse_sign f =
    match f.todo with
    | '+'::_ -> eat f
    | '-'::_ -> { (eat f) with negative = true; }
    | _ -> f

  let parse_hex_symbol f =
    match f.todo with
    | '0'::('x' | 'X')::_ -> f |> eat |> eat
    | _ -> raise No_good

  let parse_exponent f =
    let todo_str = f.todo
      |> List.map Char.escaped
      |> String.concat "" in
    let exponent =
      try int_of_string todo_str
      with Failure _ -> raise No_good in
    { f with exponent; todo = [] }

  let rec parse_body f =
    match f.todo with
    | [] -> f
    (* _ is just ignored *)
    | '_'::_ -> parse_body (eat f)
    | '.'::_ ->
        if f.decimal_exponent = None
        then parse_body { (eat f) with decimal_exponent = Some 0 }
        else raise No_good
    | ('p' | 'P')::_ ->
        parse_exponent (eat f)
    | c::_ ->
        let ref_char_code =
          if c >= '0' && c <= '9'
          then Char.code '0'
          else if c >= 'A' && c <= 'F'
          then Char.code 'A' - 10
          else if c >= 'a' && c <= 'f'
          then Char.code 'a' - 10
          else raise No_good in
        let value = (Char.code c) - ref_char_code in
        let decimal_exponent = match f.decimal_exponent with
        | None -> None
        | Some e -> Some (e - 4) in
        let mantissa = (f.mantissa lsl 4) + value in
        parse_body { (eat f) with decimal_exponent; mantissa; }

  let float_of_t f =
    assert (f.todo = []);
    let ret = float_of_int f.mantissa in
    let exponent = match f.decimal_exponent with
    | None -> f.exponent
    | Some decimal_exponent -> f.exponent + decimal_exponent in
    let ret =
      if exponent = 0
      then ret
      else ret ** (float_of_int exponent) in
    if f.negative
    then -.ret
    else ret

  let float_of_string str =
    try Pervasives.float_of_string str
    with e when Sys.win32 ->
      try
        start str
          |> parse_sign
          |> parse_hex_symbol
          |> parse_body
          |> float_of_t
      with No_good -> raise e
end

let save_comment
  (env: Lex_env.t)
  (start: Loc.t) (_end: Loc.t)
  (buf: Buffer.t)
  (multiline: bool)
: Lex_env.t =
  let open Ast.Comment in
  let loc = Loc.btwn start _end in
  let s = Buffer.contents buf in
  let c = if multiline then Block s else Line s in
  let lex_comments_acc = (loc, c) :: env.lex_state.lex_comments_acc in
  { env with lex_state = { env.lex_state with lex_comments_acc; } }

let mk_num_singleton number_type raw =
  let neg, num = if raw.[0] = '-'
    then true, String.sub raw 1 (String.length raw - 1)
    else false, raw
  in
  (* convert singleton number type into a float *)
  let value = match number_type with
  | LEGACY_OCTAL ->
    begin try Int64.to_float (Int64.of_string ("0o"^num))
    with Failure _ -> failwith ("Invalid legacy octal "^num)
    end
  | BINARY
  | OCTAL ->
    begin try Int64.to_float (Int64.of_string num)
    with Failure _ -> failwith ("Invalid binary/octal "^num)
    end
  | NORMAL ->
    begin try FloatOfString.float_of_string num
    with Failure _ -> failwith ("Invalid number "^num)
    end
  in
  let value = if neg then ~-.value else value in
  T_NUMBER_SINGLETON_TYPE { kind = number_type; value; raw }

let recover env lexbuf ~f =
  let env = illegal env (loc_of_lexbuf env lexbuf) in
  Sedlexing.rollback lexbuf;
  f env lexbuf

type jsx_text_mode =
  | JSX_SINGLE_QUOTED_TEXT
  | JSX_DOUBLE_QUOTED_TEXT
  | JSX_CHILD_TEXT

let rec token (env: Lex_env.t) lexbuf =
  match%sedlex lexbuf with
  | line_terminator_sequence ->
    let env = new_line env lexbuf in
    token env lexbuf

  | '\\' ->
    let env = illegal env (loc_of_lexbuf env lexbuf) in
    token env lexbuf

  | Plus whitespace ->
    token env lexbuf

  | "/*" ->
    let start = loc_of_lexbuf env lexbuf in
    let buf = Buffer.create 127 in
    let env, _end = comment env buf lexbuf in
    let env = save_comment env start _end buf true in
    token env lexbuf

  | "/*", Star whitespace, (":" | "::" | "flow-include") ->
    let pattern = lexeme lexbuf in
    if not (is_comment_syntax_enabled env) then
      let start = loc_of_lexbuf env lexbuf in
      let buf = Buffer.create 127 in
      Buffer.add_string buf (String.sub pattern 2 (String.length pattern - 2));
      let env, _end = comment env buf lexbuf in
      let env = save_comment env start _end buf true in
      token env lexbuf
    else
      let env =
        if is_in_comment_syntax env then
          let loc = loc_of_lexbuf env lexbuf in
          unexpected_error env loc pattern
        else env
      in
      let env = in_comment_syntax true env in
      let len = Sedlexing.lexeme_length lexbuf in
      if Sedlexing.Utf8.sub_lexeme lexbuf (len - 1) 1 = ":" &&
         Sedlexing.Utf8.sub_lexeme lexbuf (len - 2) 1 <> ":" then
        env, T_COLON
      else
        token env lexbuf

  | "*/" ->
    if is_in_comment_syntax env then
      let env = in_comment_syntax false env in
      token env lexbuf
    else begin
      Sedlexing.rollback lexbuf;
      match%sedlex lexbuf with
      | "*" -> env, T_MULT
      | _ -> failwith "expected *"
    end

  | "//" ->
    let start = loc_of_lexbuf env lexbuf in
    let buf = Buffer.create 127 in
    let env, _end = line_comment env buf lexbuf in
    let env = save_comment env start _end buf false in
    token env lexbuf

  (* Support for the shebang at the beginning of a file. It is treated like a
   * comment at the beginning or an error elsewhere *)
  | "#!" ->
    if Sedlexing.lexeme_start lexbuf = 0 then
      let env, _ = line_comment env (Buffer.create 127) lexbuf in
      token env lexbuf
    else
      env, T_ERROR "#!"

  (* Values *)
  | "'" | '"' ->
    let quote = lexeme lexbuf in
    let start = loc_of_lexbuf env lexbuf in
    let buf = Buffer.create 127 in
    let raw = Buffer.create 127 in
    Buffer.add_string raw quote;
    let octal = false in
    let env, _end, octal = string_quote env quote buf raw octal lexbuf in
    let loc = Loc.btwn start _end in
    env, T_STRING (loc, Buffer.contents buf, Buffer.contents raw, octal)

  | '`' ->
    let cooked = Buffer.create 127 in
    let raw = Buffer.create 127 in
    let literal = Buffer.create 127 in
    Buffer.add_string literal (lexeme lexbuf);

    let start = loc_of_lexbuf env lexbuf in
    let env, loc, is_tail =
      template_part env start cooked raw literal lexbuf in
    env, T_TEMPLATE_PART (
      loc,
      {
        cooked = Buffer.contents cooked;
        raw = Buffer.contents raw;
        literal = Buffer.contents literal;
      },
      is_tail
    )

  | binnumber, (letter | '2'..'9'), Star alphanumeric ->
    (* Numbers cannot be immediately followed by words *)
    recover env lexbuf ~f:(fun env lexbuf -> match%sedlex lexbuf with
    | binnumber ->
      env, T_NUMBER { kind = BINARY; raw = lexeme lexbuf }
    | _ -> failwith "unreachable"
    )

  | binnumber ->
    env, T_NUMBER { kind = BINARY; raw = lexeme lexbuf }

  | octnumber, (letter | '8'..'9'), Star alphanumeric ->
    (* Numbers cannot be immediately followed by words *)
    recover env lexbuf ~f:(fun env lexbuf -> match%sedlex lexbuf with
    | octnumber -> env, T_NUMBER { kind = OCTAL; raw = lexeme lexbuf }
    | _ -> failwith "unreachable"
    )

  | octnumber ->
    env, T_NUMBER { kind = OCTAL; raw = lexeme lexbuf }

  | legacyoctnumber, (letter | '8'..'9'), Star alphanumeric ->
    (* Numbers cannot be immediately followed by words *)
    recover env lexbuf ~f:(fun env lexbuf -> match%sedlex lexbuf with
    | legacyoctnumber -> env, T_NUMBER { kind = LEGACY_OCTAL; raw = lexeme lexbuf }
    | _ -> failwith "unreachable"
    )

  | legacyoctnumber ->
    env, T_NUMBER { kind = LEGACY_OCTAL; raw = lexeme lexbuf }

  | hexnumber, non_hex_letter, Star alphanumeric ->
    (* Numbers cannot be immediately followed by words *)
    recover env lexbuf ~f:(fun env lexbuf -> match%sedlex lexbuf with
    | hexnumber -> env, T_NUMBER { kind = NORMAL; raw = lexeme lexbuf }
    | _ -> failwith "unreachable"
    )

  | hexnumber ->
    env, T_NUMBER { kind = NORMAL; raw = lexeme lexbuf }

  | scinumber, word ->
    (* Numbers cannot be immediately followed by words *)
    recover env lexbuf ~f:(fun env lexbuf -> match%sedlex lexbuf with
    | scinumber -> env, T_NUMBER { kind = NORMAL; raw = lexeme lexbuf }
    | _ -> failwith "unreachable"
    )

  | scinumber ->
    env, T_NUMBER { kind = NORMAL; raw = lexeme lexbuf }

  | (wholenumber | floatnumber), word ->
    (* Numbers cannot be immediately followed by words *)
    recover env lexbuf ~f:(fun env lexbuf -> match%sedlex lexbuf with
    | wholenumber | floatnumber ->
      env, T_NUMBER { kind = NORMAL; raw = lexeme lexbuf }
    | _ -> failwith "unreachable"
    )

  | wholenumber | floatnumber ->
    env, T_NUMBER { kind = NORMAL; raw = lexeme lexbuf }

  (* Keywords *)
  | "async" -> env, T_ASYNC
  | "await" -> env, T_AWAIT
  | "break" -> env, T_BREAK
  | "case" -> env, T_CASE
  | "catch" -> env, T_CATCH
  | "class" -> env, T_CLASS
  | "const" -> env, T_CONST
  | "continue" -> env, T_CONTINUE
  | "debugger" -> env, T_DEBUGGER
  | "declare" -> env, T_DECLARE
  | "default" -> env, T_DEFAULT
  | "delete" -> env, T_DELETE
  | "do" -> env, T_DO
  | "else" -> env, T_ELSE
  | "enum" -> env, T_ENUM
  | "export" -> env, T_EXPORT
  | "extends" -> env, T_EXTENDS
  | "false" -> env, T_FALSE
  | "finally" -> env, T_FINALLY
  | "for" -> env, T_FOR
  | "function" -> env, T_FUNCTION
  | "if" -> env, T_IF
  | "implements" -> env, T_IMPLEMENTS
  | "import" -> env, T_IMPORT
  | "in" -> env, T_IN
  | "instanceof" -> env, T_INSTANCEOF
  | "interface" -> env, T_INTERFACE
  | "let" -> env, T_LET
  | "new" -> env, T_NEW
  | "null" -> env, T_NULL
  | "of" -> env, T_OF
  | "opaque" -> env, T_OPAQUE
  | "package" -> env, T_PACKAGE
  | "private" -> env, T_PRIVATE
  | "protected" -> env, T_PROTECTED
  | "public" -> env, T_PUBLIC
  | "return" -> env, T_RETURN
  | "static" -> env, T_STATIC
  | "super" -> env, T_SUPER
  | "switch" -> env, T_SWITCH
  | "this" -> env, T_THIS
  | "throw" -> env, T_THROW
  | "true" -> env, T_TRUE
  | "try" -> env, T_TRY
  | "type" -> env, T_TYPE
  | "typeof" -> env, T_TYPEOF
  | "var" -> env, T_VAR
  | "void" -> env, T_VOID
  | "while" -> env, T_WHILE
  | "with" -> env, T_WITH
  | "yield" -> env, T_YIELD

  (* Identifiers *)
  | js_id_start, Star js_id_continue -> env, T_IDENTIFIER (lexeme lexbuf)

  (* TODO: Use [Symbol.iterator] instead of @@iterator. *)
  | "@@iterator" -> env, T_IDENTIFIER "@@iterator"
  | "@@asyncIterator" -> env, T_IDENTIFIER "@@asyncIterator"

  (* Syntax *)
  | "{" -> env, T_LCURLY
  | "}" -> env, T_RCURLY
  | "(" -> env, T_LPAREN
  | ")" -> env, T_RPAREN
  | "[" -> env, T_LBRACKET
  | "]" -> env, T_RBRACKET
  | "..." -> env, T_ELLIPSIS
  | "." -> env, T_PERIOD
  | ";" -> env, T_SEMICOLON
  | "," -> env, T_COMMA
  | ":" -> env, T_COLON
  | "?" -> env, T_PLING
  | "&&" -> env, T_AND
  | "||" -> env, T_OR
  | "===" -> env, T_STRICT_EQUAL
  | "!==" -> env, T_STRICT_NOT_EQUAL
  | "<=" -> env, T_LESS_THAN_EQUAL
  | ">=" -> env, T_GREATER_THAN_EQUAL
  | "==" -> env, T_EQUAL
  | "!=" -> env, T_NOT_EQUAL
  | "++" -> env, T_INCR
  | "--" -> env, T_DECR
  | "<<=" -> env, T_LSHIFT_ASSIGN
  | "<<" -> env, T_LSHIFT
  | ">>=" -> env, T_RSHIFT_ASSIGN
  | ">>>=" -> env, T_RSHIFT3_ASSIGN
  | ">>>" -> env, T_RSHIFT3
  | ">>" -> env, T_RSHIFT
  | "+=" -> env, T_PLUS_ASSIGN
  | "-=" -> env, T_MINUS_ASSIGN
  | "*=" -> env, T_MULT_ASSIGN
  | "**=" -> env, T_EXP_ASSIGN
  | "%=" -> env, T_MOD_ASSIGN
  | "&=" -> env, T_BIT_AND_ASSIGN
  | "|=" -> env, T_BIT_OR_ASSIGN
  | "^=" -> env, T_BIT_XOR_ASSIGN
  | "<" -> env, T_LESS_THAN
  | ">" -> env, T_GREATER_THAN
  | "+" -> env, T_PLUS
  | "-" -> env, T_MINUS
  | "*" -> env, T_MULT
  | "**" -> env, T_EXP
  | "%" -> env, T_MOD
  | "|" -> env, T_BIT_OR
  | "&" -> env, T_BIT_AND
  | "^" -> env, T_BIT_XOR
  | "!" -> env, T_NOT
  | "~" -> env, T_BIT_NOT
  | "=" -> env, T_ASSIGN
  | "=>" -> env, T_ARROW
  | "/=" -> env, T_DIV_ASSIGN
  | "/" -> env, T_DIV
  | "@" -> env, T_AT
  | "#" -> env, T_POUND

  (* Others *)
  | eof ->
    let env =
      if is_in_comment_syntax env then
        let loc = loc_of_lexbuf env lexbuf in
        lex_error env loc Parse_error.UnexpectedEOS
      else env
    in
    env, T_EOF

  | any ->
    let env = illegal env (loc_of_lexbuf env lexbuf) in
    env, T_ERROR (lexeme lexbuf)

  | _ -> failwith "unreachable"

(* There are some tokens that never show up in a type and which can cause
 * ambiguity. For example, Foo<Bar<number>> ends with two angle brackets, not
 * with a right shift.
 *)
and type_token env lexbuf =
  match%sedlex lexbuf with
  | line_terminator_sequence ->
    let env = new_line env lexbuf in
    type_token env lexbuf

  | Plus whitespace ->
    type_token env lexbuf

  | "/*" ->
    let start = loc_of_lexbuf env lexbuf in
    let buf = Buffer.create 127 in
    let env, _end = comment env buf lexbuf in
    let env = save_comment env start _end buf true in
    type_token env lexbuf

  | "/*", Star whitespace, (":" | "::" | "flow-include") ->
    let pattern = lexeme lexbuf in
    if not (is_comment_syntax_enabled env) then
      let start = loc_of_lexbuf env lexbuf in
      let buf = Buffer.create 127 in
      Buffer.add_string buf pattern;
      let env, _end = comment env buf lexbuf in
      let env = save_comment env start _end buf true in
      type_token env lexbuf
    else
      let env =
        if is_in_comment_syntax env then
          let loc = loc_of_lexbuf env lexbuf in
          unexpected_error env loc pattern
        else env
      in
      let env = in_comment_syntax true env in
      let len = Sedlexing.lexeme_length lexbuf in
      if Sedlexing.Utf8.sub_lexeme lexbuf (len - 1) 1 = ":" &&
         Sedlexing.Utf8.sub_lexeme lexbuf (len - 2) 1 <> ":" then
        env, T_COLON
      else
        type_token env lexbuf

  | "*/" ->
    if is_in_comment_syntax env then
      let env = in_comment_syntax false env in
      type_token env lexbuf
    else begin
      Sedlexing.rollback lexbuf;
      match%sedlex lexbuf with
      | "*" -> env, T_MULT
      | _ -> failwith "expected *"
    end

  | "//" ->
    let start = loc_of_lexbuf env lexbuf in
    let buf = Buffer.create 127 in
    let env, _end = line_comment env buf lexbuf in
    let env = save_comment env start _end buf false in
    type_token env lexbuf

  | "'" | '"' ->
    let quote = lexeme lexbuf in
    let start = loc_of_lexbuf env lexbuf in
    let buf = Buffer.create 127 in
    let raw = Buffer.create 127 in
    Buffer.add_string raw quote;
    let octal = false in
    let env, _end, octal = string_quote env quote buf raw octal lexbuf in
    let loc = Loc.btwn start _end in
    env, T_STRING (loc, Buffer.contents buf, Buffer.contents raw, octal)

  (**
   * Number literals
   *)

  | Opt neg, binnumber, (letter | '2'..'9'), Star alphanumeric ->
    (* Numbers cannot be immediately followed by words *)
    recover env lexbuf ~f:(fun env lexbuf -> match%sedlex lexbuf with
    | Opt neg, binnumber ->
      let num = lexeme lexbuf in
      env, mk_num_singleton BINARY num
    | _ -> failwith "unreachable"
    )

  | Opt neg, binnumber ->
    let num = lexeme lexbuf in
    env, mk_num_singleton BINARY num

  | Opt neg, octnumber, (letter | '8'..'9'), Star alphanumeric ->
    (* Numbers cannot be immediately followed by words *)
    recover env lexbuf ~f:(fun env lexbuf -> match%sedlex lexbuf with
    | Opt neg, octnumber ->
      let num = lexeme lexbuf in
      env, mk_num_singleton OCTAL num
    | _ -> failwith "unreachable"
    )

  | Opt neg, octnumber ->
    let num = lexeme lexbuf in
    env, mk_num_singleton OCTAL num

  | Opt neg, legacyoctnumber, (letter | '8'..'9'), Star alphanumeric ->
    (* Numbers cannot be immediately followed by words *)
    recover env lexbuf ~f:(fun env lexbuf -> match%sedlex lexbuf with
    | Opt neg, legacyoctnumber ->
      let num = lexeme lexbuf in
      env, mk_num_singleton LEGACY_OCTAL num
    | _ -> failwith "unreachable"
    )

  | Opt neg, legacyoctnumber ->
    let num = lexeme lexbuf in
    env, mk_num_singleton LEGACY_OCTAL num

  | Opt neg, hexnumber, non_hex_letter, Star alphanumeric ->
    (* Numbers cannot be immediately followed by words *)
    recover env lexbuf ~f:(fun env lexbuf -> match%sedlex lexbuf with
    | Opt neg, hexnumber ->
      let num = lexeme lexbuf in
      begin try env, mk_num_singleton NORMAL num
      with _ when Sys.win32 ->
        let loc = loc_of_lexbuf env lexbuf in
        let env = lex_error env loc Parse_error.WindowsFloatOfString in
        env, T_NUMBER_SINGLETON_TYPE { kind = NORMAL; value = 789.0; raw = "789" }
      end
    | _ -> failwith "unreachable"
    )

  | Opt neg, hexnumber ->
    let num = lexeme lexbuf in
    begin try env, mk_num_singleton NORMAL num
    with _ when Sys.win32 ->
      let loc = loc_of_lexbuf env lexbuf in
      let env = lex_error env loc Parse_error.WindowsFloatOfString in
      env, T_NUMBER_SINGLETON_TYPE { kind = NORMAL; value = 789.0; raw = "789" }
    end

  | Opt neg, scinumber, word ->
    (* Numbers cannot be immediately followed by words *)
    recover env lexbuf ~f:(fun env lexbuf -> match%sedlex lexbuf with
    | Opt neg, scinumber ->
      let num = lexeme lexbuf in
      env, mk_num_singleton NORMAL num
    | _ -> failwith "unreachable"
    )

  | Opt neg, scinumber ->
    let num = lexeme lexbuf in
    env, mk_num_singleton NORMAL num

  | Opt neg, (wholenumber | floatnumber), word ->
    (* Numbers cannot be immediately followed by words *)
    recover env lexbuf ~f:(fun env lexbuf -> match%sedlex lexbuf with
    | Opt neg, wholenumber | floatnumber ->
      let num = lexeme lexbuf in
      env, mk_num_singleton NORMAL num
    | _ -> failwith "unreachable"
    )

  | Opt neg, (wholenumber | floatnumber) ->
    let num = lexeme lexbuf in
    env, mk_num_singleton NORMAL num

  (* Keywords *)
  | "any" -> env, T_ANY_TYPE
  | "bool" -> env, (T_BOOLEAN_TYPE BOOL)
  | "boolean" -> env, (T_BOOLEAN_TYPE BOOLEAN)
  | "empty" -> env, T_EMPTY_TYPE
  | "false" -> env, T_FALSE
  | "mixed" -> env, T_MIXED_TYPE
  | "null" -> env, T_NULL
  | "number" -> env, T_NUMBER_TYPE
  | "static" -> env, T_STATIC
  | "string" -> env, T_STRING_TYPE
  | "true" -> env, T_TRUE
  | "typeof" -> env, T_TYPEOF
  | "void" -> env, T_VOID_TYPE

  (* Identifiers *)
  | js_id_start, Star js_id_continue -> env, T_IDENTIFIER (lexeme lexbuf)

  | "%checks" -> env, T_CHECKS
  (* Syntax *)
  | "[" -> env, T_LBRACKET
  | "]" -> env, T_RBRACKET
  | "{" -> env, T_LCURLY
  | "}" -> env, T_RCURLY
  | "{|" -> env, T_LCURLYBAR
  | "|}" -> env, T_RCURLYBAR
  | "(" -> env, T_LPAREN
  | ")" -> env, T_RPAREN
  | "..." -> env, T_ELLIPSIS
  | "." -> env, T_PERIOD
  | ";" -> env, T_SEMICOLON
  | "," -> env, T_COMMA
  | ":" -> env, T_COLON
  | "?" -> env, T_PLING
  | "[" -> env, T_LBRACKET
  | "]" -> env, T_RBRACKET
  (* Generics *)
  | "<" -> env, T_LESS_THAN
  | ">" -> env, T_GREATER_THAN
  (* Generic default *)
  | "=" -> env, T_ASSIGN
  (* Optional or nullable *)
  | "?" -> env, T_PLING
  (* Existential *)
  | "*" -> env, T_MULT
  (* Annotation or bound *)
  | ":" -> env, T_COLON
  (* Union *)
  | '|' -> env, T_BIT_OR
  (* Intersection *)
  | '&' -> env, T_BIT_AND
  (* typeof *)
  | "typeof" -> env, T_TYPEOF
  (* Function type *)
  | "=>" -> env, T_ARROW
  (* Type alias *)
  | '=' -> env, T_ASSIGN
  (* Variance annotations *)
  | '+' -> env, T_PLUS
  | '-' -> env, T_MINUS

  (* Others *)
  | eof ->
    let env =
      if is_in_comment_syntax env then
        let loc = loc_of_lexbuf env lexbuf in
        lex_error env loc Parse_error.UnexpectedEOS
      else env
    in
    env, T_EOF

  | any ->
    env, T_ERROR (lexeme lexbuf)

  | _ -> failwith "unreachable"

(* Really simple version of string lexing. Just try to find beginning and end of
 * string. We can inspect the string later to find invalid escapes, etc *)
and string_quote env q buf raw octal lexbuf =
  match%sedlex lexbuf with
  | "'" | '"' ->
    let q' = lexeme lexbuf in
    Buffer.add_string raw q';
    if q = q'
    then env, loc_of_lexbuf env lexbuf, octal
    else begin
      Buffer.add_string buf q';
      string_quote env q buf raw octal lexbuf
    end

  | '\\' ->
    Buffer.add_string raw "\\";
    let env, str, codes, octal' = string_escape env lexbuf in
    let octal = octal' || octal in
    Buffer.add_string raw str;
    Array.iter (Wtf8.add_wtf_8 buf) codes;
    string_quote env q buf raw octal lexbuf

  | '\n' | eof ->
    let x = lexeme lexbuf in
    Buffer.add_string raw x;
    let env = illegal env (loc_of_lexbuf env lexbuf) in
    Buffer.add_string buf x;
    env, loc_of_lexbuf env lexbuf, octal

  | any ->
    let x = lexeme lexbuf in
    Buffer.add_string raw x;
    Buffer.add_string buf x;
    string_quote env q buf raw octal lexbuf

  | _ -> failwith "unreachable"

and string_escape env lexbuf =
  match%sedlex lexbuf with
  | eof
  | '\\' ->
    let str = lexeme lexbuf in
    let codes = Sedlexing.lexeme lexbuf in
    env, str, codes, false

  | 'x', hex_digit, hex_digit ->
    let str = lexeme lexbuf in
    let code = int_of_string ("0"^str) in (* 0xAB *)
    env, str, [|code|], false

  | '0'..'7', '0'..'7', '0'..'7' ->
    let str = lexeme lexbuf in
    let code = int_of_string ("0o"^str) in (* 0o012 *)
    (* If the 3 character octal code is larger than 256
     * then it is parsed as a 2 character octal code *)
    if code < 256 then
      env, str, [|code|], true
    else
      let remainder = code land 7 in
      let code = code lsr 3 in
      env, str, [|code; Char.code '0' + remainder|], true

  | '0'..'7', '0'..'7' ->
    let str = lexeme lexbuf in
    let code = int_of_string ("0o"^str) in (* 0o01 *)
    env, str, [|code|], true

  | '0' -> env, "0", [|0x0|], false
  | 'b' -> env, "b", [|0x8|], false
  | 'f' -> env, "f", [|0xC|], false
  | 'n' -> env, "n", [|0xA|], false
  | 'r' -> env, "r", [|0xD|], false
  | 't' -> env, "t", [|0x9|], false
  | 'v' -> env, "v", [|0xB|], false
  | '0'..'7' ->
    let str = lexeme lexbuf in
    let code = int_of_string ("0o"^str) in (* 0o1 *)
    env, str, [|code|], true

  | 'u', hex_digit, hex_digit, hex_digit, hex_digit ->
    let str = lexeme lexbuf in
    let hex = String.sub str 1 (String.length str - 1) in
    let code = int_of_string ("0x"^hex) in
    env, str, [|code|], false

  | "u{", Plus hex_digit, '}' ->
    let str = lexeme lexbuf in
    let hex = String.sub str 2 (String.length str - 3) in
    let code = int_of_string ("0x"^hex) in
    (* 11.8.4.1 *)
    let env = if code > 1114111
      then illegal env (loc_of_lexbuf env lexbuf)
      else env
    in
    env, str, [|code|], false

  | 'u' | 'x' | '0'..'7' ->
    let str = lexeme lexbuf in
    let codes = Sedlexing.lexeme lexbuf in
    let env = illegal env (loc_of_lexbuf env lexbuf) in
    env, str, codes, false

  | line_terminator_sequence ->
    let str = lexeme lexbuf in
    let env = new_line env lexbuf in
    env, str, [||], false

  | any ->
    let str = lexeme lexbuf in
    let codes = Sedlexing.lexeme lexbuf in
    env, str, codes, false

  | _ -> failwith "unreachable"

and comment env buf lexbuf =
  match%sedlex lexbuf with
  | line_terminator_sequence ->
    let env = new_line env lexbuf in
    Buffer.add_string buf (lexeme lexbuf);
    comment env buf lexbuf

  | "*/" ->
    let loc = loc_of_lexbuf env lexbuf in
    let env = if is_in_comment_syntax env
      then unexpected_error_w_suggest env loc "*/" "*-/"
      else env
    in
    env, loc

  | "*-/" ->
    if is_in_comment_syntax env
    then env, loc_of_lexbuf env lexbuf
    else (
      Buffer.add_string buf "*-/";
      comment env buf lexbuf
    )

  | any ->
    Buffer.add_string buf (lexeme lexbuf);
    comment env buf lexbuf

  | _ ->
    let env = illegal env (loc_of_lexbuf env lexbuf) in
    env, loc_of_lexbuf env lexbuf

and line_comment env buf lexbuf =
  match%sedlex lexbuf with
  | eof ->
    env, loc_of_lexbuf env lexbuf

  | line_terminator_sequence ->
    let { Loc.source; start; _end = { Loc.line; column; offset } }
      = loc_of_lexbuf env lexbuf in
    let env = new_line env lexbuf in
    let len = Sedlexing.lexeme_length lexbuf in
    let _end = { Loc.
      line;
      column = column - len;
      offset = offset - len;
    } in
    env, { Loc.source; start; _end; }

  | any ->
    let str = lexeme lexbuf in
    Buffer.add_string buf str;
    line_comment env buf lexbuf

  | _ -> failwith "unreachable"

and regexp env lexbuf =
  match%sedlex lexbuf with
  | eof -> env, T_EOF

  | line_terminator_sequence ->
    let env = new_line env lexbuf in
    regexp env lexbuf

  | Plus whitespace ->
    regexp env lexbuf

  | "//" ->
    let start = loc_of_lexbuf env lexbuf in
    let buf = Buffer.create 127 in
    let env, _end = line_comment env buf lexbuf in
    let env = save_comment env start _end buf false in
    regexp env lexbuf

  | "/*" ->
    let start = loc_of_lexbuf env lexbuf in
    let buf = Buffer.create 127 in
    let env, _end = comment env buf lexbuf in
    let env = save_comment env start _end buf true in
    regexp env lexbuf

  | '/' ->
    let start = loc_of_lexbuf env lexbuf in
    let buf = Buffer.create 127 in
    let env, flags = regexp_body env buf lexbuf in
    let end_ = loc_of_lexbuf env lexbuf in
    let loc = Loc.btwn start end_ in
    env, T_REGEXP (loc, Buffer.contents buf, flags)

  | any ->
    let env = illegal env (loc_of_lexbuf env lexbuf) in
    env, T_ERROR (lexeme lexbuf)

  | _ -> failwith "unreachable"

and regexp_body env buf lexbuf =
  match%sedlex lexbuf with
  | eof ->
    let loc = loc_of_lexbuf env lexbuf in
    let env = lex_error env loc Parse_error.UnterminatedRegExp in
    env, ""

  | '\\', line_terminator_sequence ->
    let loc = loc_of_lexbuf env lexbuf in
    let env = lex_error env loc Parse_error.UnterminatedRegExp in
    env, ""

  | '\\', any ->
    let s = lexeme lexbuf in
    Buffer.add_string buf s;
    regexp_body env buf lexbuf

  | '/', Plus letter ->
    let flags =
      let str = lexeme lexbuf in
      String.sub str 1 (String.length str - 1)
    in
    env, flags

  | '/' ->
    env, ""

  | '[' ->
    Buffer.add_char buf '[';
    let env = regexp_class env buf lexbuf in
    regexp_body env buf lexbuf

  | line_terminator_sequence ->
    let loc = loc_of_lexbuf env lexbuf in
    let env = lex_error env loc Parse_error.UnterminatedRegExp in
    env, ""

  | any ->
    let str = lexeme lexbuf in
    Buffer.add_string buf str;
    regexp_body env buf lexbuf

  | _ -> failwith "unreachable"


and regexp_class env buf lexbuf =
  match%sedlex lexbuf with
  | eof -> env

  | "\\\\" ->
    Buffer.add_string buf "\\\\";
    regexp_class env buf lexbuf

  | '\\', ']' ->
    Buffer.add_char buf '\\';
    Buffer.add_char buf ']';
    regexp_class env buf lexbuf

  | ']' ->
    Buffer.add_char buf ']';
    env

  | any ->
    let str = lexeme lexbuf in
    Buffer.add_string buf str;
    regexp_class env buf lexbuf

  | _ -> failwith "unreachable"


and jsx_tag env lexbuf =
  match%sedlex lexbuf with
  | eof ->
    env, T_EOF

  | line_terminator_sequence ->
    let env = new_line env lexbuf in
    jsx_tag env lexbuf

  | Plus whitespace ->
    jsx_tag env lexbuf

  | "//" ->
    let start = loc_of_lexbuf env lexbuf in
    let buf = Buffer.create 127 in
    let env, _end = line_comment env buf lexbuf in
    let env = save_comment env start _end buf false in
    jsx_tag env lexbuf

  | "/*" ->
    let start = loc_of_lexbuf env lexbuf in
    let buf = Buffer.create 127 in
    let env, _end = comment env buf lexbuf in
    let env = save_comment env start _end buf true in
    jsx_tag env lexbuf

  | '<' -> env, T_LESS_THAN
  | '/' -> env, T_DIV
  | '>' -> env, T_GREATER_THAN
  | '{' -> env, T_LCURLY
  | ':' -> env, T_COLON
  | '.' -> env, T_PERIOD
  | '=' -> env, T_ASSIGN
  | js_id_start, Star ('-' | js_id_continue) ->
    env, T_JSX_IDENTIFIER { raw = lexeme lexbuf }

  | "'" | '"' ->
    let quote = lexeme lexbuf in
    let start = loc_of_lexbuf env lexbuf in
    let buf = Buffer.create 127 in
    let raw = Buffer.create 127 in
    Buffer.add_string raw quote;
    let mode = if quote = "'"
      then JSX_SINGLE_QUOTED_TEXT
      else JSX_DOUBLE_QUOTED_TEXT in
    let env, _end = jsx_text env mode buf raw lexbuf in
    Buffer.add_string raw quote;
    let value = Buffer.contents buf in
    let raw = Buffer.contents raw in
    env, T_JSX_TEXT (Loc.btwn start _end, value, raw)

  | any ->
    env, T_ERROR (lexeme lexbuf)

  | _ -> failwith "unreachable"

and jsx_child env start buf raw lexbuf =
  match%sedlex lexbuf with
  | line_terminator_sequence ->
    let lt = lexeme lexbuf in
    Buffer.add_string raw lt;
    Buffer.add_string buf lt;
    let env = new_line env lexbuf in
    let env, _end =
      jsx_text env JSX_CHILD_TEXT buf raw lexbuf in
    let value = Buffer.contents buf in
    let raw = Buffer.contents raw in
    env, T_JSX_TEXT (Loc.btwn start _end, value, raw)

  | eof -> env, T_EOF
  | '<' -> env, T_LESS_THAN
  | '{' -> env, T_LCURLY

  | any ->
    let c = lexeme lexbuf in
    Buffer.add_string raw c;
    Buffer.add_string buf c;
    let env, _end =
      jsx_text env JSX_CHILD_TEXT buf raw lexbuf in
    let value = Buffer.contents buf in
    let raw = Buffer.contents raw in
    env, T_JSX_TEXT (Loc.btwn start _end, value, raw)

  | _ -> failwith "unreachable"

and jsx_text env mode buf raw lexbuf =
  match%sedlex lexbuf with
  | "'" | '"' | '<' | '{' ->
    let c = lexeme lexbuf in
    begin match mode, c with
    | JSX_SINGLE_QUOTED_TEXT, "'"
    | JSX_DOUBLE_QUOTED_TEXT, "\"" ->
        env, loc_of_lexbuf env lexbuf
    | JSX_CHILD_TEXT, ("<" | "{") ->
        (* Don't actually want to consume these guys
         * yet...they're not part of the JSX text *)
        Sedlexing.rollback lexbuf;
        env, loc_of_lexbuf env lexbuf
    | _ ->
        Buffer.add_string raw c;
        Buffer.add_string buf c;
        jsx_text env mode buf raw lexbuf
    end

  | eof ->
    let env = illegal env (loc_of_lexbuf env lexbuf) in
    env, loc_of_lexbuf env lexbuf

  | line_terminator_sequence ->
    let lt = lexeme lexbuf in
    Buffer.add_string raw lt;
    Buffer.add_string buf lt;
    let env = new_line env lexbuf in
    jsx_text env mode buf raw lexbuf

  | "&#x", Plus hex_digit, ';' ->
    let s = lexeme lexbuf in
    let n = String.sub s 3 (String.length s - 4) in
    Buffer.add_string raw s;
    let code = int_of_string ("0x" ^ n) in
    Wtf8.add_wtf_8 buf code;
    jsx_text env mode buf raw lexbuf

  | "&#", Plus digit, ';' ->
    let s = lexeme lexbuf in
    let n = String.sub s 2 (String.length s - 3) in
    Buffer.add_string raw s;
    let code = int_of_string n in
    Wtf8.add_wtf_8 buf code;
    jsx_text env mode buf raw lexbuf

  | "&", htmlentity, ';' ->
    let s = lexeme lexbuf in
    let entity = String.sub s 1 (String.length s - 2) in
    Buffer.add_string raw s;
    let code = match entity with
    | "quot" -> Some 0x0022
    | "amp" -> Some 0x0026
    | "apos" -> Some 0x0027
    | "lt" -> Some 0x003C
    | "gt" -> Some 0x003E
    | "nbsp" -> Some 0x00A0
    | "iexcl" -> Some 0x00A1
    | "cent" -> Some 0x00A2
    | "pound" -> Some 0x00A3
    | "curren" -> Some 0x00A4
    | "yen" -> Some 0x00A5
    | "brvbar" -> Some 0x00A6
    | "sect" -> Some 0x00A7
    | "uml" -> Some 0x00A8
    | "copy" -> Some 0x00A9
    | "ordf" -> Some 0x00AA
    | "laquo" -> Some 0x00AB
    | "not" -> Some 0x00AC
    | "shy" -> Some 0x00AD
    | "reg" -> Some 0x00AE
    | "macr" -> Some 0x00AF
    | "deg" -> Some 0x00B0
    | "plusmn" -> Some 0x00B1
    | "sup2" -> Some 0x00B2
    | "sup3" -> Some 0x00B3
    | "acute" -> Some 0x00B4
    | "micro" -> Some 0x00B5
    | "para" -> Some 0x00B6
    | "middot" -> Some 0x00B7
    | "cedil" -> Some 0x00B8
    | "sup1" -> Some 0x00B9
    | "ordm" -> Some 0x00BA
    | "raquo" -> Some 0x00BB
    | "frac14" -> Some 0x00BC
    | "frac12" -> Some 0x00BD
    | "frac34" -> Some 0x00BE
    | "iquest" -> Some 0x00BF
    | "Agrave" -> Some 0x00C0
    | "Aacute" -> Some 0x00C1
    | "Acirc" -> Some 0x00C2
    | "Atilde" -> Some 0x00C3
    | "Auml" -> Some 0x00C4
    | "Aring" -> Some 0x00C5
    | "AElig" -> Some 0x00C6
    | "Ccedil" -> Some 0x00C7
    | "Egrave" -> Some 0x00C8
    | "Eacute" -> Some 0x00C9
    | "Ecirc" -> Some 0x00CA
    | "Euml" -> Some 0x00CB
    | "Igrave" -> Some 0x00CC
    | "Iacute" -> Some 0x00CD
    | "Icirc" -> Some 0x00CE
    | "Iuml" -> Some 0x00CF
    | "ETH" -> Some 0x00D0
    | "Ntilde" -> Some 0x00D1
    | "Ograve" -> Some 0x00D2
    | "Oacute" -> Some 0x00D3
    | "Ocirc" -> Some 0x00D4
    | "Otilde" -> Some 0x00D5
    | "Ouml" -> Some 0x00D6
    | "times" -> Some 0x00D7
    | "Oslash" -> Some 0x00D8
    | "Ugrave" -> Some 0x00D9
    | "Uacute" -> Some 0x00DA
    | "Ucirc" -> Some 0x00DB
    | "Uuml" -> Some 0x00DC
    | "Yacute" -> Some 0x00DD
    | "THORN" -> Some 0x00DE
    | "szlig" -> Some 0x00DF
    | "agrave" -> Some 0x00E0
    | "aacute" -> Some 0x00E1
    | "acirc" -> Some 0x00E2
    | "atilde" -> Some 0x00E3
    | "auml" -> Some 0x00E4
    | "aring" -> Some 0x00E5
    | "aelig" -> Some 0x00E6
    | "ccedil" -> Some 0x00E7
    | "egrave" -> Some 0x00E8
    | "eacute" -> Some 0x00E9
    | "ecirc" -> Some 0x00EA
    | "euml" -> Some 0x00EB
    | "igrave" -> Some 0x00EC
    | "iacute" -> Some 0x00ED
    | "icirc" -> Some 0x00EE
    | "iuml" -> Some 0x00EF
    | "eth" -> Some 0x00F0
    | "ntilde" -> Some 0x00F1
    | "ograve" -> Some 0x00F2
    | "oacute" -> Some 0x00F3
    | "ocirc" -> Some 0x00F4
    | "otilde" -> Some 0x00F5
    | "ouml" -> Some 0x00F6
    | "divide" -> Some 0x00F7
    | "oslash" -> Some 0x00F8
    | "ugrave" -> Some 0x00F9
    | "uacute" -> Some 0x00FA
    | "ucirc" -> Some 0x00FB
    | "uuml" -> Some 0x00FC
    | "yacute" -> Some 0x00FD
    | "thorn" -> Some 0x00FE
    | "yuml" -> Some 0x00FF
    | "OElig" -> Some 0x0152
    | "oelig" -> Some 0x0153
    | "Scaron" -> Some 0x0160
    | "scaron" -> Some 0x0161
    | "Yuml" -> Some 0x0178
    | "fnof" -> Some 0x0192
    | "circ" -> Some 0x02C6
    | "tilde" -> Some 0x02DC
    | "Alpha" -> Some 0x0391
    | "Beta" -> Some 0x0392
    | "Gamma" -> Some 0x0393
    | "Delta" -> Some 0x0394
    | "Epsilon" -> Some 0x0395
    | "Zeta" -> Some 0x0396
    | "Eta" -> Some 0x0397
    | "Theta" -> Some 0x0398
    | "Iota" -> Some 0x0399
    | "Kappa" -> Some 0x039A
    | "Lambda" -> Some 0x039B
    | "Mu" -> Some 0x039C
    | "Nu" -> Some 0x039D
    | "Xi" -> Some 0x039E
    | "Omicron" -> Some 0x039F
    | "Pi" -> Some 0x03A0
    | "Rho" -> Some 0x03A1
    | "Sigma" -> Some 0x03A3
    | "Tau" -> Some 0x03A4
    | "Upsilon" -> Some 0x03A5
    | "Phi" -> Some 0x03A6
    | "Chi" -> Some 0x03A7
    | "Psi" -> Some 0x03A8
    | "Omega" -> Some 0x03A9
    | "alpha" -> Some 0x03B1
    | "beta" -> Some 0x03B2
    | "gamma" -> Some 0x03B3
    | "delta" -> Some 0x03B4
    | "epsilon" -> Some 0x03B5
    | "zeta" -> Some 0x03B6
    | "eta" -> Some 0x03B7
    | "theta" -> Some 0x03B8
    | "iota" -> Some 0x03B9
    | "kappa" -> Some 0x03BA
    | "lambda" -> Some 0x03BB
    | "mu" -> Some 0x03BC
    | "nu" -> Some 0x03BD
    | "xi" -> Some 0x03BE
    | "omicron" -> Some 0x03BF
    | "pi" -> Some 0x03C0
    | "rho" -> Some 0x03C1
    | "sigmaf" -> Some 0x03C2
    | "sigma" -> Some 0x03C3
    | "tau" -> Some 0x03C4
    | "upsilon" -> Some 0x03C5
    | "phi" -> Some 0x03C6
    | "chi" -> Some 0x03C7
    | "psi" -> Some 0x03C8
    | "omega" -> Some 0x03C9
    | "thetasym" -> Some 0x03D1
    | "upsih" -> Some 0x03D2
    | "piv" -> Some 0x03D6
    | "ensp" -> Some 0x2002
    | "emsp" -> Some 0x2003
    | "thinsp" -> Some 0x2009
    | "zwnj" -> Some 0x200C
    | "zwj" -> Some 0x200D
    | "lrm" -> Some 0x200E
    | "rlm" -> Some 0x200F
    | "ndash" -> Some 0x2013
    | "mdash" -> Some 0x2014
    | "lsquo" -> Some 0x2018
    | "rsquo" -> Some 0x2019
    | "sbquo" -> Some 0x201A
    | "ldquo" -> Some 0x201C
    | "rdquo" -> Some 0x201D
    | "bdquo" -> Some 0x201E
    | "dagger" -> Some 0x2020
    | "Dagger" -> Some 0x2021
    | "bull" -> Some 0x2022
    | "hellip" -> Some 0x2026
    | "permil" -> Some 0x2030
    | "prime" -> Some 0x2032
    | "Prime" -> Some 0x2033
    | "lsaquo" -> Some 0x2039
    | "rsaquo" -> Some 0x203A
    | "oline" -> Some 0x203E
    | "frasl" -> Some 0x2044
    | "euro" -> Some 0x20AC
    | "image" -> Some 0x2111
    | "weierp" -> Some 0x2118
    | "real" -> Some 0x211C
    | "trade" -> Some 0x2122
    | "alefsym" -> Some 0x2135
    | "larr" -> Some 0x2190
    | "uarr" -> Some 0x2191
    | "rarr" -> Some 0x2192
    | "darr" -> Some 0x2193
    | "harr" -> Some 0x2194
    | "crarr" -> Some 0x21B5
    | "lArr" -> Some 0x21D0
    | "uArr" -> Some 0x21D1
    | "rArr" -> Some 0x21D2
    | "dArr" -> Some 0x21D3
    | "hArr" -> Some 0x21D4
    | "forall" -> Some 0x2200
    | "part" -> Some 0x2202
    | "exist" -> Some 0x2203
    | "empty" -> Some 0x2205
    | "nabla" -> Some 0x2207
    | "isin" -> Some 0x2208
    | "notin" -> Some 0x2209
    | "ni" -> Some 0x220B
    | "prod" -> Some 0x220F
    | "sum" -> Some 0x2211
    | "minus" -> Some 0x2212
    | "lowast" -> Some 0x2217
    | "radic" -> Some 0x221A
    | "prop" -> Some 0x221D
    | "infin" -> Some 0x221E
    | "ang" -> Some 0x2220
    | "and" -> Some 0x2227
    | "or" -> Some 0x2228
    | "cap" -> Some 0x2229
    | "cup" -> Some 0x222A
    | "'int'" -> Some 0x222B
    | "there4" -> Some 0x2234
    | "sim" -> Some 0x223C
    | "cong" -> Some 0x2245
    | "asymp" -> Some 0x2248
    | "ne" -> Some 0x2260
    | "equiv" -> Some 0x2261
    | "le" -> Some 0x2264
    | "ge" -> Some 0x2265
    | "sub" -> Some 0x2282
    | "sup" -> Some 0x2283
    | "nsub" -> Some 0x2284
    | "sube" -> Some 0x2286
    | "supe" -> Some 0x2287
    | "oplus" -> Some 0x2295
    | "otimes" -> Some 0x2297
    | "perp" -> Some 0x22A5
    | "sdot" -> Some 0x22C5
    | "lceil" -> Some 0x2308
    | "rceil" -> Some 0x2309
    | "lfloor" -> Some 0x230A
    | "rfloor" -> Some 0x230B
    | "lang" -> Some 0x27E8 (* 0x2329 in HTML4 *)
    | "rang" -> Some 0x27E9 (* 0x232A in HTML4 *)
    | "loz" -> Some 0x25CA
    | "spades" -> Some 0x2660
    | "clubs" -> Some 0x2663
    | "hearts" -> Some 0x2665
    | "diams" -> Some 0x2666
    | _ -> None in
    (match code with
    | Some code -> Wtf8.add_wtf_8 buf code
    | None -> Buffer.add_string buf ("&" ^ entity ^";"));
    jsx_text env mode buf raw lexbuf

  | any ->
    let c = lexeme lexbuf in
    Buffer.add_string raw c;
    Buffer.add_string buf c;
    jsx_text env mode buf raw lexbuf

  | _ -> failwith "unreachable"


and template_tail env lexbuf =
  match%sedlex lexbuf with
  | line_terminator_sequence ->
    let env = new_line env lexbuf in
    template_tail env lexbuf

  | Plus whitespace ->
    template_tail env lexbuf

  | "//" ->
    let start = loc_of_lexbuf env lexbuf in
    let buf = Buffer.create 127 in
    let env, _end = line_comment env buf lexbuf in
    let env = save_comment env start _end buf false in
    template_tail env lexbuf

  | "/*" ->
    let start = loc_of_lexbuf env lexbuf in
    let buf = Buffer.create 127 in
    let env, _end = comment env buf lexbuf in
    let env = save_comment env start _end buf true in
    template_tail env lexbuf

  | '}' ->
    let start = loc_of_lexbuf env lexbuf in
    let cooked = Buffer.create 127 in
    let raw = Buffer.create 127 in
    let literal = Buffer.create 127 in
    Buffer.add_string literal "}";
    let env, loc, is_tail =
      template_part env start cooked raw literal lexbuf in
    env, (T_TEMPLATE_PART (loc, {
      cooked = Buffer.contents cooked;
      raw = Buffer.contents raw;
      literal = Buffer.contents literal;
    }, is_tail))

  | any ->
    let env = illegal env (loc_of_lexbuf env lexbuf) in
    env, (T_TEMPLATE_PART (
      loc_of_lexbuf env lexbuf,
      { cooked = ""; raw = ""; literal = ""; },
      true
    ))

  | _ -> failwith "unreachable"

and template_part env start cooked raw literal lexbuf =
  match%sedlex lexbuf with
  | eof ->
    let env = illegal env (loc_of_lexbuf env lexbuf) in
    env, Loc.btwn start (loc_of_lexbuf env lexbuf), true

  | '`' ->
    Buffer.add_char literal '`';
    env, Loc.btwn start (loc_of_lexbuf env lexbuf), true

  | "${" ->
    Buffer.add_string literal "${";
    env, Loc.btwn start (loc_of_lexbuf env lexbuf), false

  | '\\' ->
    Buffer.add_char raw '\\';
    Buffer.add_char literal '\\';
    let env, str, codes, _ = string_escape env lexbuf in
    Buffer.add_string raw str;
    Buffer.add_string literal str;
    Array.iter (Wtf8.add_wtf_8 cooked) codes;
    template_part env start cooked raw literal lexbuf

  (* ECMAScript 6th Syntax, 11.8.6.1 Static Semantics: TV's and TRV's
   * Long story short, <LF> is 0xA, <CR> is 0xA, and <CR><LF> is 0xA
   * *)
  | "\r\n" ->
    Buffer.add_string raw "\r\n";
    Buffer.add_string literal "\r\n";
    Buffer.add_string cooked "\n";
    let env = new_line env lexbuf in
    template_part env start cooked raw literal lexbuf

  | "\n" | "\r" ->
    let lf = lexeme lexbuf in
    Buffer.add_string raw lf;
    Buffer.add_string literal lf;
    Buffer.add_char cooked '\n';
    let env = new_line env lexbuf in
    template_part env start cooked raw literal lexbuf

  | any ->
    let c = lexeme lexbuf in
    Buffer.add_string raw c;
    Buffer.add_string literal c;
    Buffer.add_string cooked c;
    template_part env start cooked raw literal lexbuf

  | _ -> failwith "unreachable"


let regexp env =
  get_result_and_clear_state (regexp env env.lex_lb)

(* Lexing JSX children requires a string buffer to keep track of whitespace
 * *)
let jsx_child env =
  let start = loc_of_curr env env.lex_lb in
  let buf = Buffer.create 127 in
  let raw = Buffer.create 127 in
  let env, child = jsx_child env start buf raw env.lex_lb in
  get_result_and_clear_state (env, child)

let jsx_tag env =
  get_result_and_clear_state (jsx_tag env env.lex_lb)

let template_tail env =
  get_result_and_clear_state (template_tail env env.lex_lb)

let type_token env =
  get_result_and_clear_state (type_token env env.lex_lb)

let token env =
  get_result_and_clear_state (token env env.lex_lb)
