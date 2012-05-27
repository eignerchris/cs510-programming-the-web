# Stock News Indexer #

This application is a news discovery and browsing engine that consists of 3 components: the indexer, the processor, and a web app for browsing indexed content and managing the indexer.

## Architecture ##

### Indexer ###
The indexer is a robots.txt/sitemap-obeying recursive indexer that discovers news for stock tickers. The indexer takes as input a stock symbol, crawls the web for news articles that contain said ticker, and queues those web pages for processing by the processor. When a match is found, it is written to a key-value based datastore for processing. When

### Processor ###
The processor is a worker that polls a queue and processes key/value pairs as they arrive. A single piece of data consists of a ticker and web url tuple. When the worker receives a job, it inserts that url into a long-term datastore for the given stock ticker.

### Web App ###
The web application is a control center for operating the indexer and browsing new articles for the various stock tickers.

### Flow ###
The indexer is given a stock ticker and begins by verifying that the stock ticker is valid via an API call to FILL IN HERE. Next it fetches from a long-term datastore a set of seed domains to start crawling. For each URL discovered, the base domain is added to the set of seeds and each page tested for matches. If a match is found... 