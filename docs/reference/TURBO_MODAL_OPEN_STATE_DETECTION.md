# Turbo modal state detection — do not use `turbo-frame[src]` as a proxy

Consolidated from past incident on `feature/issue-14-keyboard-shortcuts`.

## The pitfall

In the common pattern where `turbo_frame_tag "modal"` lazy-loads a `<dialog>`-based modal from a Stimulus `turbo-modal` controller, the `src` attribute on the frame is **only cleared on click-based close paths** (close button, backdrop click — both routed through `turbo_modal_controller#hideModal` → `parentElement.removeAttribute('src')`).

**Native `<dialog>` Escape-key close does not route through `hideModal`.** The browser closes the dialog directly and fires `cancel` + `close` events, but no JS cleanup runs. The `src` attribute stays stale in the DOM for the rest of the page lifetime.

Any code that uses `modalFrame.hasAttribute('src')` as a proxy for "modal is currently visible" will return `true` forever once the user has Esc-closed any modal at least once. The bug is latent — only triggers after an Esc-close, only affects code branching on `src`.

## Correct detection

Use the real visible state maintained by `<dialog>` itself:

```js
// Any modal open?
document.querySelector('dialog[open]')

// Specific frame's contents open?
modalFrame.querySelector('dialog[open]')
```

Do not use `turboFrame.hasAttribute('src')`. `src` on a Turbo frame means "this frame's content came from this URL last" — not "the modal is currently visible".

## Regression test pattern

Any test that exercises modal-interacting code must include at least one **native Escape close** path — clicking the close button will not trigger the staleness bug.

```ruby
click_link "Test Task Two"
assert_selector "dialog.modal-base[open]"
dispatch_key("Escape")  # native dialog close, src stays set
assert_no_selector "dialog.modal-base[open]"

# Downstream shortcuts must still work after Esc-close
dispatch_key("/")
assert_selector "dialog.search-modal[open]"
```

## Deeper fix

The underlying symmetry problem is that `turbo_modal_controller` only listens for click events. Consider adding a `close@window` or `addEventListener('close', ...)` listener that removes `src` from the parent frame on any dialog close path. This fixes all current and future callers at once.

## Principle

**Imperative UI state that is cleaned up only on one of several close paths is a bug waiting to happen.** Audit the controller for symmetry: if `hideModal()` is the only place that does `removeAttribute('src')`, and there are other close paths (native Esc, programmatic `.close()`), that cleanup isn't reliable. Before introducing any new `src`-based modal-state check, grep for existing proxies — they are likely incorrect and your new code will amplify them.
