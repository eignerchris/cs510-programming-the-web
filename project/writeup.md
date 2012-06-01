# Stock News Indexer #

## Table of Contents ##

  1. Introduction
  2. Motivation
  3. Architecture
  4. Outstanding Issues
  5. Areas for Improvement
  6. Conclusion

## Introduction ##
  The purpose of this project was to test the understanding of perl, basic socket programming, HTTP protocol, and input manipulation on the web. 

## Motivation ##
  The choice to focus on indexing stock market news was based on a long, personal interest in the stock market. Knowing that the market is not a zero-sum game, I've contemplated several times building a stock analysis tool for use in trading. I'm far from the first to have this idea; many programmers and traders have had similar ambitions and there currently exists many rich analysis tools that far surpass anything I may ever build. Nevertheless, I chose this opportunity to build a stock news indexer as a building block for a hypothetical trading tool I may or may not build in the future.

## Architecture ##
  The project consists of four components: a datastore, indexer, worker, and web interface.

### Datastore ###
  The datastore I chose for this project was Redis, a highly-performant key/value store that supports lists, sets, hashes, sorted sets, and strings.  I chose this datastore for several reasons, the first being that I felt the tool mapped well to the problem. I didn't need full ACID, but I also needed more than I thought DBM could provide. I had a tertiary glance at Redis in the Cloud Database course and knew the interface to be short, clean and easy to understand. This seemed like a great opportunity to play with it.

### Indexer ###
  The indexer is a simple, robots.txt-obeying, forking, recusive indexer. The indexer takes as an argument a stock symbol and for each source in the list of sources, forks a child and begins spidering each source. If the symbol is found anywhere on the page, the indexer stores the url for the page and logs some statistics. The recusion depth for testing and demo was set to 2 levels, but nothing prevents it from being set higher. 

  The main spider function works as follows. Given a url, the indexer initially does some very basic error checking - return if the url is nil, an empty string, matches on "doubleclick", etc. Doing so prevents us from indexing content served via ads, empty links, and the like. Next we make our request, checking Redis for a cached version of the robots.txt content for the url host along the way. If it exists, we continue. If not, we fetch it and cache it for use later. If the request response is a 200, we search the page for the supplied ticker argument. Next we collect all links on the page and call the same function again for each url.

### Worker ###
  So we can index more than one stock symbol at a time, I created a 'work' queue in Redis to be polled by a worker I wrote in Perl. The worker loops indefintely, checking the queue in Redis every two seconds. Jobs are pushed onto the queue either directly via redis-cli or via the web interface. If a job is found, the worker uses the Async module to fire up the indexer and return immediately, allowing us to fetch more work from the queue and index multiple tickers are the same time. 

## Outstanding Issues ##

## Areas for Improvement ##

## Conclusion ##


5. The Spider................................................................................................................... 3
5.1. Purpose................................................................................................................ 3
5.2. Software .............................................................................................................. 3
5.3. Modules............................................................................................................... 3
6. Readability .................................................................................................................. 3
7. Style ............................................................................................................................ 4
8. Source Analysis .......................................................................................................... 5
9. Header Analysis.......................................................................................................... 6
10. Obstacles................................................................................................................. 6PROJECT DOCUMENT NAME 

1. Introduction
A 1995 web study performed by a UC Berkeley research team showed trends in the World Wide 
Web at that time.  Since then technology and interests have shifted.  This study compares the 
1995 results to current web trends and attempts to measure them.
2. Identifier

5. The Spider
5.1. Purpose
The web spider was written to take a seed URI and spider its links while analyzing 
the contents of the sites being spidered.  The Spider is the core of the project with 
individual modules supporting the source and header analysis.
5.2. Software
The source for this research is written entirely in Perl while using modules from Weblint and 
UNIX style.  A web server capable of running Perl Scripts, UNIX Style, and Weblint.
5.3. Modules
The code for analysis and display of spidered pages was separated into separate 
modules to effectively divide the work amongst group members and keep the 
efficiency of a single spider.
6. Readability
For this project, readability was measured using the Flesch-Kincaid Grade Level (1) 
formula as calculated by the UNIX style(2) utility.  It is the average score off all pages 
visited within unique domains that this report presents.  
Although the style utility is no longer a standard part of most UNIX distributions, an 
open source version of it can be found in the Diction package maintained by the Free 
Software Foundation.  The version used for this report is 'GNU style 1.02'.PROJECT DOCUMENT NAME VERSION
CS410: PTW             Web Trends Comparison 1.0
Publication Date: 8/16/03 Page 4 of 7
The scores listed in Table 1 represent the scores for each domain.  Interestingly enough, 
the domains with lower scores are considered more “readable” as they reflex web pages 
with less complex grammatical and lexical structure.
Domain Average Kincaid Readability Score
Org 13.46
englishmm 9.6
Edu 11.59
com 25.82
Net 7.29
De 19.5
Table 1: Average Kincaid Readability score for pages in visited domains
http://csep.psyc.memphis.edu/cohmetrix/readabilityresearch.htm
http://www.gnu.org/software/diction/diction.html
7. Style
This project used weblint(1) to check the syntactical correctness of each visited page.  
Twelve specific types of syntax errors were checked for and recored.  The total number 
of each type of error was then tallied.  Table 2 lists the error types checked and Table 3 
lists the count of each error for all pages visited.
Errror Type Error Description
html-outer Tags other than <HTML> and </HTML> have been found either at the 
beginning of the file or at the end of the file.
no-head The <HEAD> tag and sub-tags are missing from this file
head-element Tags that should only be within the <HEAD></HEAD> tags have been 
found elsewhere in the document.
no-body The <BODY> tag and subtags are missing from this file.
must-follow Some tags must follow other tags.  This error reports when they do not.
unclosed-element The ending tag of a set is missing.
extended-markup None standard HTML has been found in this file.  Either Netscape or 
Microsoft specific.
empty-container An opening and closing tag have no content.
mis-match The opening and closing tag of a set to not match.
heading-order Rarely seen.  Some heading tags (H1, H2) must come before others.  
This reports on that type of error.
Tags-overlap When two sets are overlapped rather than encapsulated.
unkown-attr An unknown tag or tag attribute has been found.  It's possible that IE or 
Netscape have added tags or attributes that weblint is not yet 
programmed to understand.
Table 2: Description of the twelve types of errors checked.
Error Type Error Count
Html-outer 4
no-head 16PROJECT DOCUMENT NAME VERSION
CS410: PTW             Web Trends Comparison 1.0
Publication Date: 8/16/03 Page 5 of 7
Error Type Error Count
Head-element 76
no-body 4
Must-follow 145
unclosed-element 265
extended-markup 113033
empty-container 6197
mis-match 0
heading-order 0
Tags-overlap 0
unkown-attr 33452
Table 3: Total count of error types for the pages visited.
(1)http://www.cre.canon.co.uk/~neilb/weblint/
8. Source Analysis
In an effort to recreate the 1995 UC Berkeley study, the source was fed into a module that 
specifically analyzed the text for HTML tags, length, ratios, and links.  Apart from the 
spider, this module had the most valuable results.
Tag Usage: 
Number of Tags 462722
Title 4804 
Anchor 44828 
Paragraph 8751 
HR 1152 
IMG 16004 
HEAD 9905 
HTML 10403 
BR 27544 
META 499 
HREF 0 
SRC 131421 
ALIGN 89554 
ALT 336 
NAME 21909 
SIZE 46639 
BORDER 42087 
WIDTH  25144 
BACKGROUND 212 
BGCOLOR  1892 
Docs (in-links) Per Domain: 90
org  213 
phtml  8
com support  1
English 1
commencement  1
Bin 1
Html 6
com cgi-bin 1
net  8
de  16
r  202
edu 180
s 22
com aboutus  1
com offerspecial  1
com  6609
Port Usage: 
other 90
80 7271PROJECT DOCUMENT NAME VERSION
CS410: PTW             Web Trends Comparison 1.0
Publication Date: 8/16/03 Page 6 of 7
There are a number of interesting results to look at, but one in particular may raise 
questions to the validity of the results.  The number of documents spidered as stated 
before was 4,818 but the port usage indicates a much greater number.  This is due to the 
fact that the counter was only incremented when the module to analyze source was 
called.  Many pages returned error codes other than 200 OK and were counted in the port 
usage figures but subsequently not evaluated for source.
9. Header Analysis
The header information for each page spidered was analyzed for return code, softare 
version, length, and type (in addition to other data).  
File Types:  596 
application/pdf  6 
text/x-unknown-content-type 1 
application/msword  2 
text/html  6756 
Response Codes: 
400  2 
200 4826
500  3
403  14
404  140
301  4
302  1778 
Software Versions:  797 
Apache/1.3.12  38 
Apache/1.3.20  7 
Microsoft-IIS/5.0  178 
Apache/1.3.14  1 
Oracle9iAS/9.0.2  5 
Apache/1.3.23 1 
Apache/1.3.26  66 
Netscape-Enterprise/3.6  1 
Apache/1.3.27  4582 
Apache/1.3.19  5 
Apache/1.3.28  8 
Apache  1 
Netscape-Enterprise/6.0  1 
Netitor  1 
Zope/(unreleased)  38 
Netscape-Enterprise/3.5.1G 2 
WebSitePro/2.5.8  1 
Microsoft-IIS/4.0  1628 
Avg HTML Document Size: 
10956.7648401826 
The average HTML document size stayed about the same in our sample to the 1995 
study, which we found to be surprising since the number of tags required for new 
languages such as JavaScript and VBScript would likely increase the size of an HTML 
document significantly.
Of the spidering there were an unusually high number of 302 return codes (25%) which 
indicates a lot of server redirects are taking place either from URL alias names in the 
links, or from mirror site redirections.
10. Obstacles 
After spidering 4,818 pages and viewing several thousand more the spider stopped 
collecting data and hung as a process.  We suspect that the reason for this is that the 
Weblint module code is opening a new process for each call of the module without a 
specific kill of the process and therefore eventually reaching the process limit.PROJECT DOCUMENT NAME VERSION
CS410: PTW             Web Trends Comparison 1.0
Publication Date: 8/16/03 Page 7 of 7
The 1995 study produced very detailed results but our research had a difficult time 
reproducing the conditions needed to mimic those tests in part due to large differences in 
technology, but also related to time constraints on the research project.