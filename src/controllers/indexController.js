const brreg = require('../models/brregModel.js');

const { createClient } = require('redis');

const client = createClient({
    url: process.env.REDIS_URI,
});
client.connect();

const orgQuery = async (req, res) => {
    try {
        const { orgNumber } = req.body;

        if (!orgNumber) {
            return res.status(422).json({ message: "No organization number provided" });
        }

        const cacheQuery = await client.get(orgNumber);
        if (cacheQuery) {
            return res.status(200).json(JSON.parse(cacheQuery));
        }

        const data = await brreg.findOne({ organisasjonsnummer: orgNumber });
        
        if (!data) {
            return res.status(404).json({ message: "Organization not found" });
        }

        return res.status(200).json(data);
    } catch(error) {
        console.error('Query error:', error);
        return res.status(500).json({ message: 'Internal server error' });
    }
};

const nameQuery = async (req, res) => {
    try {
        const { name } = req.body;

        if (!name) {
            return res.status(422).json({ message: "No organization number provided" });
        }

        if (typeof name !== "string") {
            return res.status(400).json({ message: "Invalid name provided" });
        }

        const cacheQuery = await client.get(name);
        if (cacheQuery) {
            return res.status(200).json(JSON.parse(cacheQuery));
        }

        const exactMatchQuery = brreg.findOne({ navn: { $eq: name } }).limit(5);

        const similarMatchQuery = brreg.findOne(
            { $text: { $search: name } },
            { score: { $meta: 'textScore' } })
            .sort({ score: { $meta: 'textScore' } })
            .limit(5);

        const timeout = new Promise((_, reject) => {
            setTimeout(() => {
                reject(new Error('Queries timed out after 5 seconds'));
            }, 5000);
        });

        const result = await Promise.race([
            exactMatchQuery.exec(),
            similarMatchQuery.exec(),
            timeout
        ]);

        if (!result) {
            return res.status(404).json({ message: "Organization not found" });
        }

        await client.set(name, JSON.stringify(result), { EX: 60 });
        return res.status(200).json(result);

    } catch(error) {
        console.error('Query error:', error);
        return res.status(500).json({ message: 'Internal server error' });
    }
};

const indexPage = async (req, res) => {
    res.render('index.ejs');
};

module.exports = { 
    orgQuery,
    nameQuery,
    indexPage
};