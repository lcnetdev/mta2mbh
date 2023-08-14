# mta2mbh

XSLT v1.0 application to convert MARC Title Authority records into
MARC "Bib Hub" Work descriptions.

## Contents
* [Introduction](#introduction)
* [Examples](#examples)
* [Dependencies](#dependencies)
* [Usage](#usage)
    * [Stylesheet parameters](#stylesheet-parameters)
* [Specifications](#specifications)
* [Testing](#testing)
* [Design notes](#design-notes)
* [License](#license)

## Introduction

_mta2mbh_ is an XSLT v1.0 stylesheet that converts name-title and 
title [authority records](https://www.loc.gov/marc/authority/) encoded 
as [MARCXML](https://www.loc.gov/standards/marcxml/) (either a single record or 
a MARC collection) into "Bib Hub" Work descriptions -- sparse 
MARC [bibliographic records](https://www.loc.gov/marc/bibliographic/) built from 
the authority records. This is an experimental data conversion project which 
creates MARC records that contain fields, subfields, and indicator values not 
currently defined in the MARC [bibliographic format](https://loc.gov/marc/bibliographic/).  In
addition, treatment of series treatment fields (from the authority 
record [64X fields](https://www.loc.gov/marc/authority/ad64x.html)) is 
under review and may change in future versions of this stylesheet.

For more background about the genesis of this conversion, see the [Report on examination of MARC 
Title Authorities](https://listserv.loc.gov/cgi-bin/wa?A2=MARC;89de296e.2206).  In 
addition to providing more detailed description behind the motives for this 
experimental data conversion, it details the (relatively) few additions and changes needed
to the MARC Bibliographic format to further this idea.

## Examples

MARC "Bib Hub" descriptions can be viewed at [ID.LOC.GOV](https://id.loc.gov/).  A link can
be found at the bottom of all Title or NameTitle pages such as [this one](https://id.loc.gov/authorities/names/n94123751.html).  

There is also a [comparison service](https://id.loc.gov/tools/compare/mta2mbh/?lccn=n94123751) that facilitates side-by-side comparison.

## Dependencies

* [date:date-time()](http://exslt.org/date/functions/date-time/index.html)
  or [fn:current-dateTime()](https://docs.marklogic.com/fn:current-dateTime)
  -- to create a timestamp for the generated MARC 884 data field. If
  no `pConversionDatestamp` parameter is provided and neither function
  is available, the 884 $g will not be generated (see
  [Stylesheet parameters](#stylesheet-parameters) below).

* [exsl:node-set()](http://exslt.org/exsl/functions/node-set/index.html)
  -- to allow for sorting the MARC fields in the output MARC record in
  tag order. If this function is not available, the fields in the
  record will not be in tag order.

## Usage

    xsltproc mta2mbh.xsl test/data/mta.xml

### Stylesheet parameters

* `pConversionDatestamp` -- a static datestamp in the form YYYYMMDD
  for inclusion in a generated MARC 884 $g. If this parameter is not
  provided, a datestamp will be generated using `date:date-time()` or
  `fn:current-dateTime()` (see [Dependencies](#dependencies) above).

* `pConversionAgency` -- the MARC code of the agency performing the
  conversion, for inclusion in a generated MARC 884 $q. Defaults to
  "DLC"

* `pConversionURI` -- a URI for the conversion program. Defaults to
  the Github repository for this application
  (https://github.com/lcnetdev/mta2mbh).

Different XSLT processors have different syntaxes for passing
parameters. For xsltproc, the syntax is:

    xsltproc --stringparam pConversionAgency HCO mta2mbh.xsl test/data/mta.xml

## Specifications

The specifications for the conversion are in the [spec](spec)
directory.

## Testing

The test suite for the application is in the [test](test) directory,
with test data in the [test/data](test/data) directory.

The tests are written for the [XSpec](https://github.com/xspec/xspec)
testing framework, a behavior driven development testing framework for
XSLT and XQuery. To run the tests, you must install the Saxon XSLT and
XQuery processor as well as XSpec. Installation instructions are
available on the [XSpec wiki](https://github.com/xspec/xspec/wiki).

Once you have XSpec installed, you can run the test suite with the
command (for Mac OS or Linux):

    xspec.sh test/mta2mbh.xspec

Test reports will be output in the test/xspec directory.

## Design notes

_mta2mbh_ is designed as a single-stylesheet XSLT application.

* For best performance, _mta2mbh_ has a "push" design that deals with
  each source MARC field only once as much as possible.

* The MARC fields are assembled as a result tree fragment in an XSLT
  variable, so that they can be sorted in tag order for output.

## License
As a work of the United States government, this project is in the
public domain within the United States.

Additionally, we waive copyright and related rights in the work
worldwide through the CC0 1.0 Universal public domain dedication.

[Legal Code (read the full text)](https://creativecommons.org/publicdomain/zero/1.0/legalcode).

You can copy, modify, distribute and perform the work, even for
commercial purposes, all without asking permission.
