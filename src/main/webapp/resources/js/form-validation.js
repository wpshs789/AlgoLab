/**
 * AlgoLab's validation messages follow the selected site language, not the browser/OS language.
 * The browser still enforces native HTML constraints, including required/min/max/step.
 * JSP pages supply translated messages via data-error-* attributes.
 */
(function () {
    'use strict';

    function messageFor(field) {
        const v = field.validity;
        if (v.valueMissing) return field.dataset.errorRequired || field.dataset.errorInvalid || '';
        if (v.rangeOverflow || v.rangeUnderflow) return field.dataset.errorRange || field.dataset.errorInvalid || '';
        if (v.badInput || v.stepMismatch || v.typeMismatch) {
            return field.dataset.errorNumber || field.dataset.errorInvalid || '';
        }
        if (v.tooLong || v.tooShort || v.patternMismatch) {
            return field.dataset.errorInvalid || '';
        }
        return field.dataset.errorInvalid || '';
    }

    document.querySelectorAll('[data-error-required]').forEach(function (field) {
        // HTML validation runs before the form's submit event. The invalid event is the
        // earliest reliable place to replace a localized browser validation bubble.
        field.addEventListener('invalid', function () {
            // Clear any previous custom error so the actual current constraint can be read.
            field.setCustomValidity('');
            if (!field.validity.valid) {
                field.setCustomValidity(messageFor(field));
            }
        });
        // A custom message persists until cleared, even after the input becomes valid.
        // Clear it on every edit so a corrected field is immediately submit-ready.
        field.addEventListener('input', function () {
            field.setCustomValidity('');
        });
        field.addEventListener('change', function () {
            field.setCustomValidity('');
        });
    });
})();
