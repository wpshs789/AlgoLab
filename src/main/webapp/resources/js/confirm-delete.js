/** Site-localized delete confirmation: no Chrome/OS-language buttons. */
(function () {
    'use strict';
    const forms = document.querySelectorAll('form[data-confirm-message]');
    if (!forms.length) return;

    const dialog = document.createElement('dialog');
    dialog.className = 'algolab-confirm-dialog';
    dialog.setAttribute('aria-labelledby', 'algolabConfirmTitle');
    dialog.setAttribute('aria-describedby', 'algolabConfirmMessage');

    const heading = document.createElement('div');
    heading.className = 'algolab-confirm-heading';
    const mark = document.createElement('span');
    mark.className = 'algolab-confirm-mark';
    mark.setAttribute('aria-hidden', 'true');
    mark.textContent = '!';
    const copy = document.createElement('div');
    const title = document.createElement('h2');
    title.id = 'algolabConfirmTitle';
    title.className = 'algolab-confirm-title';
    const message = document.createElement('p');
    message.id = 'algolabConfirmMessage';
    message.className = 'algolab-confirm-message';
    copy.append(title, message);
    heading.append(mark, copy);

    const actions = document.createElement('div');
    actions.className = 'algolab-confirm-actions';
    const cancel = document.createElement('button');
    cancel.type = 'button';
    cancel.className = 'algolab-confirm-cancel';
    const approve = document.createElement('button');
    approve.type = 'button';
    approve.className = 'algolab-confirm-approve';
    actions.append(cancel, approve);
    dialog.append(heading, actions);
    document.body.append(dialog);

    let pending = null;
    function confirmSubmission(form) {
        form.dataset.algolabConfirmed = 'true';
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
                if (window.confirm(form.dataset.confirmMessage || '')) confirmSubmission(form);
                return;
            }
            pending = form;
            message.textContent = form.dataset.confirmMessage || '';
            title.textContent = form.dataset.confirmOk || 'Delete';
            cancel.textContent = form.dataset.confirmCancel || 'Cancel';
            approve.textContent = form.dataset.confirmOk || 'Delete';
            dialog.showModal();
            cancel.focus(); // Safer default: pressing Enter won't accidentally delete.
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
