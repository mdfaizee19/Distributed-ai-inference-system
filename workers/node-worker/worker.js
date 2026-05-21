/*
 JavaScript worker service.
 Receives internal requests from Python worker.
*/

const express = require('express');

const app = express();

app.use(express.json());

app.post('/analyze', (req, res) => {
    const { prompt } = req.body;

    if (!prompt) {
        return res.status(400).json({
            error: 'Prompt is required'
        });
    }

    console.log(`Received prompt: ${prompt}`);

    return res.json({
        result: 'Processed by Node worker',
        input: prompt
    });
});

app.listen(5002, () => {
    console.log('Node worker listening on port 5002');
});