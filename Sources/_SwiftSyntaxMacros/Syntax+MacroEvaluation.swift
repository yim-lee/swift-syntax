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

import SwiftDiagnostics
import SwiftSyntax

extension MacroExpansionExprSyntax {
  /// Evaluate the given macro for this syntax node, producing the expanded
  /// result and (possibly) some diagnostics.
  func evaluateMacro(
    _ macro: Macro.Type,
    in context: MacroEvaluationContext,
    errorHandler: (MacroSystemError) -> Void
  ) -> ExprSyntax {
    guard let exprMacro = macro as? ExpressionMacro.Type else {
      errorHandler(.requiresExpressionMacro(macro: macro, node: Syntax(self)))
      return ExprSyntax(self)
    }

    // Handle the rewrite.
    let result = exprMacro.apply(self, in: context)

    // Report diagnostics, if there were any.
    if !result.diagnostics.isEmpty {
      errorHandler(
        .evaluationDiagnostics(
          node: Syntax(self), diagnostics: result.diagnostics
        )
      )
    }

    return result.rewritten
  }
}

extension MacroExpansionDeclSyntax {
  /// Macro expansion declarations are parsed in some positions where an
  /// expression is also warranted, so
  private func asMacroExpansionExpr() -> MacroExpansionExprSyntax {
    MacroExpansionExprSyntax(
      unexpectedBeforePoundToken, poundToken: poundToken,
      unexpectedBetweenPoundTokenAndMacro, macro: macro,
      genericArguments: genericArguments,
      unexpectedBetweenGenericArgumentsAndLeftParen, leftParen: leftParen,
      unexpectedBetweenLeftParenAndArgumentList, argumentList: argumentList,
      unexpectedBetweenArgumentListAndRightParen, rightParen: rightParen,
      unexpectedBetweenRightParenAndTrailingClosure,
      trailingClosure: trailingClosure,
      unexpectedBetweenTrailingClosureAndAdditionalTrailingClosures,
      additionalTrailingClosures: additionalTrailingClosures,
      unexpectedAfterAdditionalTrailingClosures
    )
  }

  /// Evaluate the given macro for this syntax node, producing the expanded
  /// result and (possibly) some diagnostics.
  func evaluateMacro(
    _ macro: Macro.Type,
    in context: MacroEvaluationContext,
    errorHandler: (MacroSystemError) -> Void
  ) -> Syntax {
    // TODO: declaration/statement macros

    // Fall back to evaluating as an expression macro.
    return Syntax(
      asMacroExpansionExpr().evaluateMacro(
        macro, in: context, errorHandler: errorHandler
      )
    )
  }
}

extension Syntax {
  /// Determine the name of the macro that is evaluated by this syntax node,
  /// if indeed it is a macro evaluation. For example, "#stringify(x)" has the
  /// name "stringify".
  public var evaluatedMacroName: String? {
    switch self.as(SyntaxEnum.self) {
    case .macroExpansionDecl(let expansion):
      return expansion.macro.text

    case .macroExpansionExpr(let expansion):
      return expansion.macro.text

    default:
      return nil
    }
  }

  /// Evaluate the given macro and return the resulting syntax tree along with
  /// any errors along the way.
  ///
  /// This operation only makes sense when `evaluatedMacroName` produces a
  /// non-nil value, indicating that this syntax node is a macro evaluation of
  /// some kind.
  public func evaluateMacro(
    with macroSystem: MacroSystem,
    context: MacroEvaluationContext,
    errorHandler: (MacroSystemError) -> Void
  ) -> Syntax {
    // If this isn't a macro evaluation node, do nothing.
    guard let macroName = evaluatedMacroName else {
      return self
    }

    // Look for a macro with the given name. Otherwise, fail.
    guard let macro = macroSystem.macros[macroName] else {
      errorHandler(.unknownMacro(name: macroName, node: self))
      return self
    }

    switch self.as(SyntaxEnum.self) {
    case .macroExpansionDecl(let expansion):
      return expansion.evaluateMacro(
        macro, in: context, errorHandler: errorHandler
      )

    case .macroExpansionExpr(let expansion):
      return Syntax(
        expansion.evaluateMacro(
          macro, in: context, errorHandler: errorHandler
        )
      )

    default:
      fatalError("switch is out-of-sync with evaluatedMacroName")
    }
  }
}
