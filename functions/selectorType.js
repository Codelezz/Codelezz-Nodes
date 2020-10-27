const NODES_PATH = 'nodes';
const SELECTOR_PATH = 'selectors';
const TYPE_PATH = 'type';
const SELECTOR_TYPES_PATH = 'selector-types';

module.exports = (targetVal) => {
    const types = Object.keys(targetVal[SELECTOR_TYPES_PATH]);
    const result = [];
    
    for(const nodeId of Object.keys(targetVal[NODES_PATH])) {
        const selectors = targetVal[NODES_PATH][nodeId][SELECTOR_PATH];
        for(const selectorId of Object.keys(selectors)) {
            const type = selectors[selectorId][TYPE_PATH];
            if(!types.includes(type)) {
                result.push({
                    message: `${type} must be defined in ${SELECTOR_TYPES_PATH}`,
                    path: [NODES_PATH, nodeId, SELECTOR_PATH, selectorId, TYPE_PATH]
                })
            }
        }
    }

    return result;
}