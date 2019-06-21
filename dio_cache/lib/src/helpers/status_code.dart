import 'dart:io';

isValidHttpStatusCode(int code) => const [HttpStatus.ok, HttpStatus.created, HttpStatus.accepted].contains(code);