# Contributing to erc8004-builder-kit

Thank you for your interest in contributing! This guide will help you get started.

## How to Contribute

### Reporting Issues

- Use the [Bug Report](.github/ISSUE_TEMPLATE/bug_report.md) template for bugs
- Use the [Feature Request](.github/ISSUE_TEMPLATE/feature_request.md) template for new ideas
- Search existing issues before creating a new one

### Pull Requests

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/my-feature`
3. Make your changes
4. Test your changes (see below)
5. Commit with a clear message: `git commit -m "Add: description of change"`
6. Push to your fork: `git push origin feature/my-feature`
7. Open a Pull Request using the [PR template](.github/pull_request_template.md)

### What We're Looking For

- **New guides**: Real-world implementation patterns, case studies, or protocol guides
- **Bug fixes**: Corrections to contract addresses, code examples, or broken links
- **Script improvements**: New verification checks, additional chain support
- **Example code**: New starter templates (e.g., Go, Rust, Python/Django)
- **Translations**: Guides in other languages (especially Spanish, Portuguese, Chinese)

### Content Guidelines

- All documentation should be based on **real implementation experience**, not theory
- Include on-chain transaction hashes when referencing real deployments
- Code examples must be tested and working
- Keep content chain-agnostic where possible (ERC-8004 works on 19+ chains)
- Use English for code comments; markdown content can be bilingual

### Testing Your Changes

```bash
# Validate shell scripts
bash -n scripts/*.sh

# Check for broken internal links (install markdown-link-check)
npx markdown-link-check docs/**/*.md

# Verify no local paths leaked
grep -r "/Users/" docs/ examples/ scripts/

# Build TypeScript example
cd examples/typescript-hono && npm install && npm run build
```

### Commit Message Format

```
<type>: <description>

Types:
  Add:    New content or feature
  Fix:    Bug fix or correction
  Update: Improvement to existing content
  Docs:   Documentation-only change
  Script: Changes to shell scripts
```

## Code of Conduct

Be respectful, constructive, and inclusive. We're all here to build the agentic web together.

## Questions?

Open an issue with the "question" label or reach out to the maintainers.
