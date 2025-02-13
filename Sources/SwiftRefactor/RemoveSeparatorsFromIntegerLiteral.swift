//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2022 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

import SwiftSyntax

/// Format an integer literal by removing any existing separators.
///
/// ## Before
///
/// ```swift
/// 123_456_789
/// 0xF_FFFF_FFFF
/// ```
/// ## After
///
/// ```swift
/// 123456789
/// 0xFFFFFFFFF
/// ```
public struct RemoveSeparatorsFromIntegerLiteral: RefactoringProvider {
  public static func refactor(syntax lit: IntegerLiteralExprSyntax, in context: Void) -> IntegerLiteralExprSyntax? {
    guard lit.digits.text.contains("_") else {
      return lit
    }
    let formattedText = lit.digits.text.filter({ $0 != "_" })
    return lit
      .withDigits(lit.digits.withKind(.integerLiteral(formattedText)))
  }
}
