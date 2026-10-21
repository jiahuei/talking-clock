# Guide for AI agents

## Core Principles

- **Validate the Approach Before Implementing**: For non-trivial changes, distinguish the required outcome from the proposed implementation. Treat suggestions, including those in issues and plans, as hypotheses to validate.
  1. Identify the required behavior and existing state that must be preserved.
  2. Check existing code and native platform capabilities for a solution that requires less change.
  3. Resolve uncertain behavior through authoritative documentation or a focused experiment before coding.
  4. Require evidence that a simpler approach is insufficient before adding complexity or performing a destructive operation.
  5. Derive tests from required behavior and preservation requirements rather than assumptions about the implementation.

  Keep this proportional: straightforward changes do not need a written alternatives analysis.

## Subagent Strategy

- Ask reviewers to challenge the necessity of the proposed mechanism and identify simpler existing alternatives, as well as checking correctness.
