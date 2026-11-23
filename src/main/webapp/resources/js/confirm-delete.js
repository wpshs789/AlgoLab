/** Localized custom confirmation dialog: window.confirm button labels follow Chrome/OS language. */
(function () {
    'use strict';
    const forms = document.querySelectorAll('form[data-confirm-message]');
    if (!forms.length) return;

    const dialog = document.createElement('dialog');
    dialog.className = 'algolab-confirm-dialog';
    dialog.setAttribute('aria-labelledby', 'algolabConfirmMessage');
    const message = document.createElement('p');
    message.id = 'algolabConfirmMessage';
    const actions = document.createElement('div');
    actions.className = 'algolab-confirm-actions';
    const cancel = document.createElement('button');
    cancel.type = 'button';
    cancel.className = 'algolab-confirm-cancel';
    const approve = document.createElement('button');
    approve.type = 'button';
    approve.className = 'algolab-confirm-approve';
    actions.append(cancel, approve);
    dialog.append(message, actions);
    document.body.append(dialog);
    let pending = null;

    function confirmSubmission(form) {
        form.dataset.algolabConfirmed = 'true';
        // requestSubmit() preserves submit handlers and native validation.
        if (typeof form.requestSubmit === 'function') form.requestSubmit();
        else form.submit();
    }

    forms.forEach(function (form) {
        form.addEventListener('submit', function (event) {
            if (form.dataset.algolabConfirmed === 'true') {
                delete form.dataset.algolabConfirmed;
                return;
            }
            event.preventDefault();
            if (typeof dialog.showModal !== 'function') {
                // Graceful fallback for older browsers (only then uses native controls).
                if (window.confirm(form.dataset.confirmMessage)) confirmSubmission(form);
                return;
            }
            pending = form;
            message.textContent = form.dataset.confirmMessage || '';
            cancel.textContent = form.dataset.confirmCancel || 'Cancel';
            approve.textContent = form.dataset.confirmOk || 'Delete';
            dialog.showModal();
        });
    });
    cancel.addEventListener('click', function () { dialog.close(); });
    approve.addEventListener('click', function () {
        const form = pending;
        dialog.close();
        if (form) confirmSubmission(form);
    });
    dialog.addEventListener('close', function () { pending = null; });
})();
