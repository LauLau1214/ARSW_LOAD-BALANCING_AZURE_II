const { app } = require('@azure/functions');
const bigInt = require('big-integer');
const os = require('os');

// La cache vive en la memoria de la instancia: se pierde cuando la instancia se recicla
const memo = new Map([[0, bigInt.zero], [1, bigInt.one]]);

const MAX_NTH = 20000;
const STEP = 500;

function fib(n) {
    if (memo.has(n)) {
        return memo.get(n);
    }
    const value = fib(n - 1).add(fib(n - 2));
    memo.set(n, value);
    return value;
}

// Recorre la recursion en tramos para no superar la profundidad maxima de la pila
function fibMemo(n) {
    for (let k = STEP; k < n; k += STEP) {
        fib(k);
    }
    return fib(n);
}

app.http('FibonacciMemo', {
    methods: ['GET', 'POST'],
    authLevel: 'anonymous',
    handler: async (request, context) => {
        context.log('FibonacciMemo function processed a request.');

        let nth = request.query.get('nth');
        if (nth === null) {
            try {
                nth = (await request.json()).nth;
            } catch (e) {
                nth = undefined;
            }
        }
        nth = Number(nth);

        if (!Number.isInteger(nth) || nth < 0 || nth > MAX_NTH) {
            return { status: 400, body: `nth must be an integer between 0 and ${MAX_NTH}` };
        }

        const cached = memo.has(nth);
        const start = process.hrtime.bigint();
        const answer = fibMemo(nth).toString();
        const computeMs = Number(process.hrtime.bigint() - start) / 1e6;

        return {
            jsonBody: {
                nth,
                digits: answer.length,
                answerStart: answer.substring(0, 30),
                cached,
                computeMs: Math.round(computeMs * 1000) / 1000,
                cacheEntries: memo.size,
                instanceUptimeSeconds: Math.round(process.uptime()),
                instance: (process.env.WEBSITE_INSTANCE_ID || os.hostname()).substring(0, 12)
            }
        };
    }
});
