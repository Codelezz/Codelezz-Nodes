const IMPLEMENTS_PATH = 'implements';
const SELECTOR_TYPES_PATH = 'selector-types';
const BLANK = 'blank';

module.exports = (targetVal) => {
    const types = targetVal[SELECTOR_TYPES_PATH];
    const typesIds = Object.keys(types);
    const result = [];

    for (const id of typesIds.filter(t => t !== 'blank')) {
        const type = types[id];
        const imp = type[IMPLEMENTS_PATH]
        if (!imp) {
            result.push({
                message: `${id} must specify an implementation.`,
                path: [SELECTOR_TYPES_PATH, id]
            })
        } else if (!Array.isArray(imp)) {
            result.push({
                message: `${camelize(IMPLEMENTS_PATH)} must be an array.`,
                path: [SELECTOR_TYPES_PATH, id]
            })
        } else if (imp.length === 0) {
            result.push({
                message: `${camelize(IMPLEMENTS_PATH)} cannot be empty.`,
                path: [SELECTOR_TYPES_PATH, id]
            })

        } else if (imp.includes(id)) {
            result.push({
                message: `${camelize(IMPLEMENTS_PATH)} cannot contain itself.`,
                path: [SELECTOR_TYPES_PATH, id]
            })
        } else if (!traceToBlank(types, id, imp, [])) {
            result.push({
                message: `${camelize(IMPLEMENTS_PATH)} must always trace back to blank.`,
                path: [SELECTOR_TYPES_PATH, id]
            })
        } else if (!traceNotCircular(types, id, imp, [])) {
            result.push({
                message: `${camelize(IMPLEMENTS_PATH)} cannot have a circular dependency.`,
                path: [SELECTOR_TYPES_PATH, id]
            })
        }
    }

    return result;
}

function traceNotCircular(selectors, id, imp, been) {
    if (id === BLANK) return true;
    if (!imp) return false;
    if (!Array.isArray(imp)) return false;
    return imp.filter(i => i !== id).every(i => {
        if (been.includes(i)) return false;
        const s = selectors[i];
        if (!s) return false;
        return traceNotCircular(selectors, i, s[IMPLEMENTS_PATH], [...been, id]);
    })
}

function traceToBlank(selectors, id, imp, been) {
    if (!imp) return false;
    if (!Array.isArray(imp)) return false;
    if (imp.includes(BLANK)) return true;
    return imp.filter(i => i !== id && !been.includes(i)).some(i => {
        const s = selectors[i];
        if (!s) return false;
        return traceToBlank(selectors, i, s[IMPLEMENTS_PATH], [...been, id]);
    })
}

function camelize(str) {
    return str.substring(0, 1).toUpperCase() + str.substring(1);
}