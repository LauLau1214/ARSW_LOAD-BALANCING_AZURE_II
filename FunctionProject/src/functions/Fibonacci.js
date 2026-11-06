const { app } = require('@azure/functions');
const bigInt = require('big-integer');

app.http('Fibonacci', {
    methods: ['GET', 'POST'],
    authLevel: 'anonymous',
    handler: async (request, context) => {
        context.log('JavaScript HTTP trigger function processed a request.');

        const { nth } = await request.json();
        let nth_1 = bigInt.one;
        let nth_2 = bigInt.zero;
        let answer = bigInt.zero;

        if (nth < 0)
            throw 'must be greater than 0';
        else if (nth === 0)
            answer = nth_2;
        else if (nth === 1)
            answer = nth_1;
        else {
            for (var i = 0; i < nth - 1; i++) {
                answer = nth_2.add(nth_1);
                nth_2 = nth_1;
                nth_1 = answer;
            }
        }

        return { body: answer.toString() };
    }
});