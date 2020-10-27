module.exports = (targetVal, _opts, paths) => {
    if (!Array.isArray(targetVal)) {
        return;
    }

    const seen = [];
    const results = [];

    const rootPath = paths.target !== void 0 ? paths.target : paths.given;

    for (let i = 0; i < targetVal.length; i++) {
        if (targetVal[i] === null || typeof targetVal[i] !== 'string') {
            continue;
        }

        const tagName = targetVal[i];

        if (seen.includes(tagName)) {
            results.push(
                {
                    message: `Duplicate value '${tagName}'`,
                    path: [...rootPath, i]
                },
            );
        } else {
            seen.push(tagName);
        }
    }

    return results;
};