// Credit: https://davidwells.io/blog/cleaner-async-await-code-without-try-catch

/* Native Error types https://mzl.la/2Veh3TR */
const nativeExceptions = [
    EvalError,
    RangeError,
    ReferenceError,
    SyntaxError,
    TypeError,
    URIError
].filter((except) => typeof except === 'function');

/* Throw native errors. ref: https://bit.ly/2VsoCGE */
function throwNative(error) {
    for (const Exception of nativeExceptions) {
        if (error instanceof Exception) throw error;
    }
}

/* Helper buddy for removing async/await try/catch litter */
function safeAwait(promise, finallyFunc) {
    return promise
        .then((data) => {
            if (data instanceof Error) {
                throwNative(data);
                return [data];
            }
            return [undefined, data];
        })
        .catch((error) => {
            throwNative(error);
            return [error];
        })
        .finally(() => {
            if (finallyFunc && typeof finallyFunc === 'function') {
                finallyFunc();
            }
        });
}

export default safeAwait;
