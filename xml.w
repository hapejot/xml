@*XML.
gjobread.c : a small test program for gnome jobs XML format |Daniel.Veillard@w3.org|
@c
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <stdbool.h>
@
This example should compile and run indifferently with libxml-1.8.8 +
and libxml2-2.1.0 +
Check the COMPAT comments below

COMPAT using xml-config --cflags to get the include path this will
work with both 
@f xmlChar      int
@f xmlDocPtr    int
@f xmlNsPtr     int
@f xmlNodePtr   int
@f xmlCharEncodingHandlerPtr int
@f xmlTextWriterPtr int
@c
#include <libxml/xmlmemory.h>
#include <libxml/parser.h>

@
A person record
an |xmlChar *| is really an UTF8 encoded char string (0 terminated)
@c
typedef struct person {
    xmlChar *name;
    xmlChar *email;
    xmlChar *company;
    xmlChar *organisation;
    xmlChar *smail;
    xmlChar *webPage;
    xmlChar *phone;
} person, *personPtr;
@
And the code needed to parse it
@c
static personPtr parsePerson(xmlDocPtr doc, xmlNsPtr ns, xmlNodePtr cur) {
    personPtr ret = NULL;

    /*
     * allocate the struct
     */
    ret = (personPtr) malloc(sizeof(person));
    if (ret == NULL) {
        fprintf(stderr,"out of memory\n");
    return(NULL);
    }
    memset(ret, 0, sizeof(person));

    /* We don't care what the top level element name is */
    /* COMPAT xmlChildrenNode is a macro unifying libxml1 and libxml2 names */
    cur = cur->xmlChildrenNode;
    while (cur != NULL) {
        if ((!xmlStrcmp(cur->name, (const xmlChar *)"Person")) &&
        (cur->ns == ns))
        ret->name = xmlNodeListGetString(doc, cur->xmlChildrenNode, 1);
        if ((!xmlStrcmp(cur->name, (const xmlChar *)"Email")) &&
        (cur->ns == ns))
        ret->email = xmlNodeListGetString(doc, cur->xmlChildrenNode, 1);
    cur = cur->next;
    }

    return(ret);
}
@
and to print it
@c
static void printPerson(personPtr cur) {
    if (cur == NULL) return;
    printf("------ Person\n");
    if (cur->name) printf(" name: %s\n", cur->name);
    if (cur->email) printf("    email: %s\n", cur->email);
    if (cur->company) printf("  company: %s\n", cur->company);
    if (cur->organisation) printf(" organisation: %s\n", cur->organisation);
    if (cur->smail) printf("    smail: %s\n", cur->smail);
    if (cur->webPage) printf("  Web: %s\n", cur->webPage);
    if (cur->phone) printf("    phone: %s\n", cur->phone);
    printf("------\n");
}
@
a Description for a Job
@c
typedef struct job {
    xmlChar *projectID;
    xmlChar *application;
    xmlChar *category;
    personPtr contact;
    int nbDevelopers;
    personPtr developers[100]; /* using dynamic alloc is left as an exercise */
} job, *jobPtr;
@
And the code needed to parse it
@c
static jobPtr parseJob(xmlDocPtr doc, xmlNsPtr ns, xmlNodePtr cur) {
    jobPtr ret = NULL;

    /*
     * allocate the struct
     */
    ret = (jobPtr) malloc(sizeof(job));
    if (ret == NULL) {
        fprintf(stderr,"out of memory\n");
    return(NULL);
    }
    memset(ret, 0, sizeof(job));

    /* We don't care what the top level element name is */
    cur = cur->xmlChildrenNode;
    while (cur != NULL) {
        
        if ((!xmlStrcmp(cur->name, (const xmlChar *) "Project")) &&
        (cur->ns == ns)) {
        ret->projectID = xmlGetProp(cur, (const xmlChar *) "ID");
        if (ret->projectID == NULL) {
        fprintf(stderr, "Project has no ID\n");
        }
    }
    if ((!xmlStrcmp(cur->name, (const xmlChar *) "Application")) &&
        (cur->ns == ns))
    ret->application = 
    xmlNodeListGetString(doc, cur->xmlChildrenNode, 1);
    if ((!xmlStrcmp(cur->name, (const xmlChar *) "Category")) &&
    (cur->ns == ns))
    ret->category =
    xmlNodeListGetString(doc, cur->xmlChildrenNode, 1);
    if ((!xmlStrcmp(cur->name, (const xmlChar *) "Contact")) &&
    (cur->ns == ns))
    ret->contact = parsePerson(doc, ns, cur);
    cur = cur->next;
    }

    return(ret);
}
@
and to print it
@c
static void printJob(jobPtr cur) {
    int i;

    if (cur == NULL) return;
    printf("=======  Job\n");
    if (cur->projectID != NULL) printf("projectID: %s\n", cur->projectID);
    if (cur->application != NULL) printf("application: %s\n", cur->application);
    if (cur->category != NULL) printf("category: %s\n", cur->category);
    if (cur->contact != NULL) printPerson(cur->contact);
    printf("%d developers\n", cur->nbDevelopers);

    for (i = 0;i < cur->nbDevelopers;i++) printPerson(cur->developers[i]);
    printf("======= \n");
}
@
A pool of Gnome Jobs
@c
typedef struct gjob {
    int nbJobs;
    jobPtr jobs[500]; /* using dynamic alloc is left as an exercise */
} gJob, *gJobPtr;

@ handle root element as boolean function returning the value in the first parameter.
This way one can cascade the function into a sequence of |&&| symbols.
@c
static bool readRoot(xmlNodePtr*cur, xmlDocPtr doc){
    *cur = xmlDocGetRootElement(doc);
    if (*cur == NULL) {
        fprintf(stderr,"empty document\n");
        xmlFreeDoc(doc);
        return false;
    }
    else
        return true;
}
@
@c
static bool checkNamespace(xmlNsPtr *ns, xmlDocPtr doc,xmlNodePtr cur){
    *ns = xmlSearchNsByHref(doc, cur,
            (const xmlChar *) "http://www.gnome.org/some-location");
    if (*ns == NULL) {
        fprintf(stderr,
                "document of the wrong type, GJob Namespace not found\n");
        xmlFreeDoc(doc);
        return false;
    }
    else 
        return true;
}
@
@c
static gJobPtr parseGjobFile(char *filename) {
    xmlDocPtr doc;
    gJobPtr ret;
    jobPtr curjob;
    xmlNsPtr ns;
    xmlNodePtr cur;


    doc = xmlParseFile(filename);     /* build an XML tree from a the file */
    if (doc == NULL) return(NULL);

    
    if(readRoot(&cur, doc)
            && checkNamespace(&ns, doc, cur)){ /* Check the document is of the right kind */
        if (xmlStrcmp(cur->name, (const xmlChar *) "Helping")) {
            fprintf(stderr,"document of the wrong type, root node != Helping");
        xmlFreeDoc(doc);
        return(NULL);
        }

        
        ret = (gJobPtr) malloc(sizeof(gJob)); /* Allocate the structure to be returned.  */
        if (ret == NULL) {
            fprintf(stderr,"out of memory\n");
        xmlFreeDoc(doc);
        return(NULL);
        }
        memset(ret, 0, sizeof(gJob));

        /*
        * Now, walk the tree.
        */
        /* First level we expect just Jobs */
        cur = cur->xmlChildrenNode;
        while ( cur && xmlIsBlankNode ( cur ) ) {
        cur = cur -> next;
        }
        if ( cur == 0 ) {
        xmlFreeDoc(doc);
        free(ret);
        return ( NULL );
        }
        if ((xmlStrcmp(cur->name, (const xmlChar *) "Jobs")) || (cur->ns != ns)) {
            fprintf(stderr,"document of the wrong type, was '%s', Jobs expected",
            cur->name);
        fprintf(stderr,"xmlDocDump follows\n");
        xmlDocDump ( stderr, doc );
        fprintf(stderr,"xmlDocDump finished\n");
        xmlFreeDoc(doc);
        free(ret);
        return(NULL);
        }

        /* Second level is a list of Job, but be laxist */
        cur = cur->xmlChildrenNode;
        while (cur != NULL) {
            if ((!xmlStrcmp(cur->name, (const xmlChar *) "Job")) &&
            (cur->ns == ns)) {
            curjob = parseJob(doc, ns, cur);
            if (curjob != NULL)
                ret->jobs[ret->nbJobs++] = curjob;
                if (ret->nbJobs >= 500) break;
        }
        cur = cur->next;
        }

        return(ret);
    }
    else
        return NULL;
}
@
@c
static void handleGjob(gJobPtr cur) {
    int i;

    /*
     * Do whatever you want and free the structure.
     */
    printf("%d Jobs registered\n", cur->nbJobs);
    for (i = 0; i < cur->nbJobs; i++) printJob(cur->jobs[i]);
}
@
@c
int main(int argc, char **argv) {
    int i;
    gJobPtr cur;

    /* COMPAT: Do not generate nodes for formatting spaces */
    LIBXML_TEST_VERSION
    xmlKeepBlanksDefault(0);

    for (i = 1; i < argc ; i++) {
    cur = parseGjobFile(argv[i]);
    if ( cur )
      handleGjob(cur);
    else
      fprintf( stderr, "Error parsing file '%s'\n", argv[i]);

    }

    /* Clean up everything else before quitting. */
    xmlCleanupParser();

    return(0);
}


@ dummy file

@(dummy.c@>=
// dummy file

#define XPUBLIC

XPUBLIC void dummy(){

}


@ Writer

@(testWriter.c@>=
#include <stdio.h>
#include <string.h>
#include <libxml/encoding.h>
#include <libxml/xmlwriter.h>

#define MY_ENCODING "ISO-8859-1"

void testXmlwriterFilename(const char *uri);
void testXmlwriterMemory(const char *file);
void testXmlwriterDoc(const char *file);
void testXmlwriterTree(const char *file);
xmlChar *ConvertInput(const char *in, const char *encoding);
@
@(testWriter.c@>=
int main(void)
{
    /*
     * this initialize the library and check potential ABI mismatches
     * between the version it was compiled for and the actual shared
     * library used.
     */
    LIBXML_TEST_VERSION;

    testXmlwriterFilename("writer1.tmp");
    testXmlwriterMemory("writer2.tmp");
    testXmlwriterDoc("writer3.tmp");
    testXmlwriterTree("writer4.tmp");
    xmlCleanupParser();
    xmlMemoryDump();
    return 0;
}
@
@(testWriter.c@>=
void
testXmlwriterFilename(const char *uri)
{
    int rc;
    xmlTextWriterPtr writer;
    xmlChar *tmp;

    /* Create a new XmlWriter for uri, with no compression. */
    writer = xmlNewTextWriterFilename(uri, 0);
    if (writer == NULL) {
        printf("testXmlwriterFilename: Error creating the xml writer\n");
        return;
    }

    /* Start the document with the xml default for the version,
     * encoding ISO 8859-1 and the default for the standalone
     * declaration. */
    rc = xmlTextWriterStartDocument(writer, NULL, MY_ENCODING, NULL);
    if (rc < 0) {
        printf
            ("testXmlwriterFilename: Error at xmlTextWriterStartDocument\n");
        return;
    }

    /* Start an element named "EXAMPLE". Since thist is the first
     * element, this will be the root element of the document. */
    rc = xmlTextWriterStartElement(writer,  "EXAMPLE");
    if (rc < 0) {
        printf
            ("testXmlwriterFilename: Error at xmlTextWriterStartElement\n");
        return;
    }

    /* Write a comment as child of EXAMPLE.
     * Please observe, that the input to the xmlTextWriter functions
     * HAS to be in UTF-8, even if the output XML is encoded
     * in iso-8859-1 */
    tmp = ConvertInput("This is a comment with special chars: <\xE4\xF6\xFC>",
                       MY_ENCODING);
    rc = xmlTextWriterWriteComment(writer, tmp);
    if (rc < 0) {
        printf
            ("testXmlwriterFilename: Error at xmlTextWriterWriteComment\n");
        return;
    }
    if (tmp != NULL) xmlFree(tmp);

    /* Start an element named "ORDER" as child of EXAMPLE. */
    rc = xmlTextWriterStartElement(writer,  "ORDER");
    if (rc < 0) {
        printf
            ("testXmlwriterFilename: Error at xmlTextWriterStartElement\n");
        return;
    }

    /* Add an attribute with name "version" and value "1.0" to ORDER. */
    rc = xmlTextWriterWriteAttribute(writer,  "version",
                                      "1.0");
    if (rc < 0) {
        printf
            ("testXmlwriterFilename: Error at xmlTextWriterWriteAttribute\n");
        return;
    }

    /* Add an attribute with name "xml:lang" and value "de" to ORDER. */
    rc = xmlTextWriterWriteAttribute(writer,  "xml:lang",
                                      "de");
    if (rc < 0) {
        printf
            ("testXmlwriterFilename: Error at xmlTextWriterWriteAttribute\n");
        return;
    }

    /* Write a comment as child of ORDER */
    tmp = ConvertInput("<\xE4\xF6\xFC>", MY_ENCODING);
    rc = xmlTextWriterWriteFormatComment(writer,
		     "This is another comment with special chars: %s",
		     tmp);
    if (rc < 0) {
        printf
            ("testXmlwriterFilename: Error at xmlTextWriterWriteFormatComment\n");
        return;
    }
    if (tmp != NULL) xmlFree(tmp);

    /* Start an element named |"HEADER"| as child of ORDER. */
    rc = xmlTextWriterStartElement(writer,  "HEADER");
    if (rc < 0) {
        printf
            ("testXmlwriterFilename: Error at xmlTextWriterStartElement\n");
        return;
    }

    /* Write an element named |"X_ORDER_ID"| as child of HEADER. */
    rc = xmlTextWriterWriteFormatElement(writer,  "X_ORDER_ID",
                                         "%010d", 53535);
    if (rc < 0) {
        printf
            ("testXmlwriterFilename: Error at xmlTextWriterWriteFormatElement\n");
        return;
    }

    /* Write an element named |"CUSTOMER_ID"| as child of HEADER. */
    rc = xmlTextWriterWriteFormatElement(writer,  "CUSTOMER_ID",
                                         "%d", 1010);
    if (rc < 0) {
        printf
            ("testXmlwriterFilename: Error at xmlTextWriterWriteFormatElement\n");
        return;
    }

    /* Write an element named |"NAME_1"| as child of HEADER. */
    tmp = ConvertInput("M\xFCller", MY_ENCODING);
    rc = xmlTextWriterWriteElement(writer,  "NAME_1", tmp);
    if (rc < 0) {
        printf
            ("testXmlwriterFilename: Error at xmlTextWriterWriteElement\n");
        return;
    }
    if (tmp != NULL) xmlFree(tmp);

    /* Write an element named |"NAME_2"| as child of HEADER. */
    tmp = ConvertInput("J\xF6rg", MY_ENCODING);
    rc = xmlTextWriterWriteElement(writer,  "NAME_2", tmp);
    if (rc < 0) {
        printf
            ("testXmlwriterFilename: Error at xmlTextWriterWriteElement\n");
        return;
    }
    if (tmp != NULL) xmlFree(tmp);

    /* Close the element named HEADER. */
    rc = xmlTextWriterEndElement(writer);
    if (rc < 0) {
        printf
            ("testXmlwriterFilename: Error at xmlTextWriterEndElement\n");
        return;
    }

    /* Start an element named |"ENTRIES"| as child of ORDER. */
    rc = xmlTextWriterStartElement(writer,  "ENTRIES");
    if (rc < 0) {
        printf
            ("testXmlwriterFilename: Error at xmlTextWriterStartElement\n");
        return;
    }

    /* Start an element named |"ENTRY"| as child of ENTRIES. */
    rc = xmlTextWriterStartElement(writer,  "ENTRY");
    if (rc < 0) {
        printf
            ("testXmlwriterFilename: Error at xmlTextWriterStartElement\n");
        return;
    }

    /* Write an element named |"ARTICLE"| as child of ENTRY. */
    rc = xmlTextWriterWriteElement(writer,  "ARTICLE",
                                    "<Test>");
    if (rc < 0) {
        printf
            ("testXmlwriterFilename: Error at xmlTextWriterWriteElement\n");
        return;
    }

    /* Write an element named |"ENTRY_NO"| as child of ENTRY. */
    rc = xmlTextWriterWriteFormatElement(writer,  "ENTRY_NO", "%d",
                                         10);
    if (rc < 0) {
        printf
            ("testXmlwriterFilename: Error at xmlTextWriterWriteFormatElement\n");
        return;
    }

    /* Close the element named ENTRY. */
    rc = xmlTextWriterEndElement(writer);
    if (rc < 0) {
        printf
            ("testXmlwriterFilename: Error at xmlTextWriterEndElement\n");
        return;
    }

    /* Start an element named |"ENTRY"| as child of ENTRIES. */
    rc = xmlTextWriterStartElement(writer,  "ENTRY");
    if (rc < 0) {
        printf
            ("testXmlwriterFilename: Error at xmlTextWriterStartElement\n");
        return;
    }

    /* Write an element named |"ARTICLE"| as child of ENTRY. */
    rc = xmlTextWriterWriteElement(writer,  "ARTICLE",
                                    "<Test 2>");
    if (rc < 0) {
        printf
            ("testXmlwriterFilename: Error at xmlTextWriterWriteElement\n");
        return;
    }

    /* Write an element named |"ENTRY_NO"| as child of ENTRY. */
    rc = xmlTextWriterWriteFormatElement(writer,  "ENTRY_NO", "%d",
                                         20);
    if (rc < 0) {
        printf
            ("testXmlwriterFilename: Error at xmlTextWriterWriteFormatElement\n");
        return;
    }

    /* Close the element named ENTRY. */
    rc = xmlTextWriterEndElement(writer);
    if (rc < 0) {
        printf
            ("testXmlwriterFilename: Error at xmlTextWriterEndElement\n");
        return;
    }

    /* Close the element named ENTRIES. */
    rc = xmlTextWriterEndElement(writer);
    if (rc < 0) {
        printf
            ("testXmlwriterFilename: Error at xmlTextWriterEndElement\n");
        return;
    }

    /* Start an element named |"FOOTER"| as child of ORDER. */
    rc = xmlTextWriterStartElement(writer,  "FOOTER");
    if (rc < 0) {
        printf
            ("testXmlwriterFilename: Error at xmlTextWriterStartElement\n");
        return;
    }

    /* Write an element named |"TEXT"| as child of FOOTER. */
    rc = xmlTextWriterWriteElement(writer,  "TEXT",
                                    "This is a text.");
    if (rc < 0) {
        printf
            ("testXmlwriterFilename: Error at xmlTextWriterWriteElement\n");
        return;
    }

    /* Close the element named FOOTER. */
    rc = xmlTextWriterEndElement(writer);
    if (rc < 0) {
        printf
            ("testXmlwriterFilename: Error at xmlTextWriterEndElement\n");
        return;
    }

    /* Here we could close the elements ORDER and EXAMPLE using the
     * function |xmlTextWriterEndElement|, but since we do not want to
     * write any other elements, we simply call |xmlTextWriterEndDocument|,
     * which will do all the work. */
    rc = xmlTextWriterEndDocument(writer);
    if (rc < 0) {
        printf
            ("testXmlwriterFilename: Error at xmlTextWriterEndDocument\n");
        return;
    }

    xmlFreeTextWriter(writer);
}
@
@(testWriter.c@>=
void
testXmlwriterMemory(const char *file)
{
    int rc;
    xmlTextWriterPtr writer;
    xmlBufferPtr buf;
    xmlChar *tmp;
    FILE *fp;

    /* Create a new XML buffer, to which the XML document will be
     * written */
    buf = xmlBufferCreate();
    if (buf == NULL) {
        printf("testXmlwriterMemory: Error creating the xml buffer\n");
        return;
    }

    /* Create a new XmlWriter for memory, with no compression.
     * Remark: there is no compression for this kind of xmlTextWriter */
    writer = xmlNewTextWriterMemory(buf, 0);
    if (writer == NULL) {
        printf("testXmlwriterMemory: Error creating the xml writer\n");
        return;
    }

    /* Start the document with the xml default for the version,
     * encoding ISO 8859-1 and the default for the standalone
     * declaration. */
    rc = xmlTextWriterStartDocument(writer, NULL, MY_ENCODING, NULL);
    if (rc < 0) {
        printf
            ("testXmlwriterMemory: Error at xmlTextWriterStartDocument\n");
        return;
    }

    /* Start an element named "EXAMPLE". Since thist is the first
     * element, this will be the root element of the document. */
    rc = xmlTextWriterStartElement(writer,  "EXAMPLE");
    if (rc < 0) {
        printf
            ("testXmlwriterMemory: Error at xmlTextWriterStartElement\n");
        return;
    }

    /* Write a comment as child of EXAMPLE.
     * Please observe, that the input to the xmlTextWriter functions
     * HAS to be in UTF-8, even if the output XML is encoded
     * in iso-8859-1 */
    tmp = ConvertInput("This is a comment with special chars: <\xE4\xF6\xFC>",
                       MY_ENCODING);
    rc = xmlTextWriterWriteComment(writer, tmp);
    if (rc < 0) {
        printf
            ("testXmlwriterMemory: Error at xmlTextWriterWriteComment\n");
        return;
    }
    if (tmp != NULL) xmlFree(tmp);

    /* Start an element named |"ORDER"| as child of EXAMPLE. */
    rc = xmlTextWriterStartElement(writer,  "ORDER");
    if (rc < 0) {
        printf
            ("testXmlwriterMemory: Error at xmlTextWriterStartElement\n");
        return;
    }

    /* Add an attribute with name "version" and value "1.0" to ORDER. */
    rc = xmlTextWriterWriteAttribute(writer,  "version",
                                      "1.0");
    if (rc < 0) {
        printf
            ("testXmlwriterMemory: Error at xmlTextWriterWriteAttribute\n");
        return;
    }

    /* Add an attribute with name "xml:lang" and value "de" to ORDER. */
    rc = xmlTextWriterWriteAttribute(writer,  "xml:lang",
                                      "de");
    if (rc < 0) {
        printf
            ("testXmlwriterMemory: Error at xmlTextWriterWriteAttribute\n");
        return;
    }

    /* Write a comment as child of ORDER */
    tmp = ConvertInput("<\xE4\xF6\xFC>", MY_ENCODING);
    rc = xmlTextWriterWriteFormatComment(writer,
		     "This is another comment with special chars: %s",
                                         tmp);
    if (rc < 0) {
        printf
            ("testXmlwriterMemory: Error at xmlTextWriterWriteFormatComment\n");
        return;
    }
    if (tmp != NULL) xmlFree(tmp);

    /* Start an element named "HEADER" as child of ORDER. */
    rc = xmlTextWriterStartElement(writer,  "HEADER");
    if (rc < 0) {
        printf
            ("testXmlwriterMemory: Error at xmlTextWriterStartElement\n");
        return;
    }

    /* Write an element named |"X_ORDER_ID"| as child of HEADER. */
    rc = xmlTextWriterWriteFormatElement(writer,  "X_ORDER_ID",
                                         "%010d", 53535);
    if (rc < 0) {
        printf
            ("testXmlwriterMemory: Error at xmlTextWriterWriteFormatElement\n");
        return;
    }

    /* Write an element named |"CUSTOMER_ID"| as child of HEADER. */
    rc = xmlTextWriterWriteFormatElement(writer,  "CUSTOMER_ID",
                                         "%d", 1010);
    if (rc < 0) {
        printf
            ("testXmlwriterMemory: Error at xmlTextWriterWriteFormatElement\n");
        return;
    }

    /* Write an element named |"NAME_1"| as child of HEADER. */
    tmp = ConvertInput("M\xFCller", MY_ENCODING);
    rc = xmlTextWriterWriteElement(writer,  "NAME_1", tmp);
    if (rc < 0) {
        printf
            ("testXmlwriterMemory: Error at xmlTextWriterWriteElement\n");
        return;
    }
    if (tmp != NULL) xmlFree(tmp);

    /* Write an element named |"NAME_2"| as child of HEADER. */
    tmp = ConvertInput("J\xF6rg", MY_ENCODING);
    rc = xmlTextWriterWriteElement(writer,  "NAME_2", tmp);

    if (rc < 0) {
        printf
            ("testXmlwriterMemory: Error at xmlTextWriterWriteElement\n");
        return;
    }
    if (tmp != NULL) xmlFree(tmp);

    /* Close the element named HEADER. */
    rc = xmlTextWriterEndElement(writer);
    if (rc < 0) {
        printf("testXmlwriterMemory: Error at xmlTextWriterEndElement\n");
        return;
    }

    /* Start an element named "ENTRIES" as child of ORDER. */
    rc = xmlTextWriterStartElement(writer,  "ENTRIES");
    if (rc < 0) {
        printf
            ("testXmlwriterMemory: Error at xmlTextWriterStartElement\n");
        return;
    }

    /* Start an element named "ENTRY" as child of ENTRIES. */
    rc = xmlTextWriterStartElement(writer,  "ENTRY");
    if (rc < 0) {
        printf
            ("testXmlwriterMemory: Error at xmlTextWriterStartElement\n");
        return;
    }

    /* Write an element named "ARTICLE" as child of ENTRY. */
    rc = xmlTextWriterWriteElement(writer,  "ARTICLE",
                                    "<Test>");
    if (rc < 0) {
        printf
            ("testXmlwriterMemory: Error at xmlTextWriterWriteElement\n");
        return;
    }

    /* Write an element named |"ENTRY_NO"| as child of ENTRY. */
    rc = xmlTextWriterWriteFormatElement(writer,  "ENTRY_NO", "%d",
                                         10);
    if (rc < 0) {
        printf
            ("testXmlwriterMemory: Error at xmlTextWriterWriteFormatElement\n");
        return;
    }

    /* Close the element named ENTRY. */
    rc = xmlTextWriterEndElement(writer);
    if (rc < 0) {
        printf("testXmlwriterMemory: Error at xmlTextWriterEndElement\n");
        return;
    }

    /* Start an element named "ENTRY" as child of ENTRIES. */
    rc = xmlTextWriterStartElement(writer,  "ENTRY");
    if (rc < 0) {
        printf
            ("testXmlwriterMemory: Error at xmlTextWriterStartElement\n");
        return;
    }

    /* Write an element named "ARTICLE" as child of ENTRY. */
    rc = xmlTextWriterWriteElement(writer,  "ARTICLE",
                                    "<Test 2>");
    if (rc < 0) {
        printf
            ("testXmlwriterMemory: Error at xmlTextWriterWriteElement\n");
        return;
    }

    /* Write an element named |"ENTRY_NO"| as child of ENTRY. */
    rc = xmlTextWriterWriteFormatElement(writer,  "ENTRY_NO", "%d",
                                         20);
    if (rc < 0) {
        printf
            ("testXmlwriterMemory: Error at xmlTextWriterWriteFormatElement\n");
        return;
    }

    /* Close the element named ENTRY. */
    rc = xmlTextWriterEndElement(writer);
    if (rc < 0) {
        printf("testXmlwriterMemory: Error at xmlTextWriterEndElement\n");
        return;
    }

    /* Close the element named ENTRIES. */
    rc = xmlTextWriterEndElement(writer);
    if (rc < 0) {
        printf("testXmlwriterMemory: Error at xmlTextWriterEndElement\n");
        return;
    }

    /* Start an element named "FOOTER" as child of ORDER. */
    rc = xmlTextWriterStartElement(writer,  "FOOTER");
    if (rc < 0) {
        printf
            ("testXmlwriterMemory: Error at xmlTextWriterStartElement\n");
        return;
    }

    /* Write an element named "TEXT" as child of FOOTER. */
    rc = xmlTextWriterWriteElement(writer,  "TEXT",
                                    "This is a text.");
    if (rc < 0) {
        printf
            ("testXmlwriterMemory: Error at xmlTextWriterWriteElement\n");
        return;
    }

    /* Close the element named FOOTER. */
    rc = xmlTextWriterEndElement(writer);
    if (rc < 0) {
        printf("testXmlwriterMemory: Error at xmlTextWriterEndElement\n");
        return;
    }

    /* Here we could close the elements ORDER and EXAMPLE using the
     * function xmlTextWriterEndElement, but since we do not want to
     * write any other elements, we simply call xmlTextWriterEndDocument,
     * which will do all the work. */
    rc = xmlTextWriterEndDocument(writer);
    if (rc < 0) {
        printf("testXmlwriterMemory: Error at xmlTextWriterEndDocument\n");
        return;
    }

    xmlFreeTextWriter(writer);

    fp = fopen(file, "w");
    if (fp == NULL) {
        printf("testXmlwriterMemory: Error at fopen\n");
        return;
    }

    fprintf(fp, "%s", (const char *) buf->content);

    fclose(fp);

    xmlBufferFree(buf);
}
@
@(testWriter.c@>=
void
testXmlwriterDoc(const char *file)
{
    int rc;
    xmlTextWriterPtr writer;
    xmlChar *tmp;
    xmlDocPtr doc;


    /* Create a new XmlWriter for DOM, with no compression. */
    writer = xmlNewTextWriterDoc(&doc, 0);
    if (writer == NULL) {
        printf("testXmlwriterDoc: Error creating the xml writer\n");
        return;
    }

    /* Start the document with the xml default for the version,
     * encoding ISO 8859-1 and the default for the standalone
     * declaration. */
    rc = xmlTextWriterStartDocument(writer, NULL, MY_ENCODING, NULL);
    if (rc < 0) {
        printf("testXmlwriterDoc: Error at xmlTextWriterStartDocument\n");
        return;
    }

    /* Start an element named "EXAMPLE". Since thist is the first
     * element, this will be the root element of the document. */
    rc = xmlTextWriterStartElement(writer,  "EXAMPLE");
    if (rc < 0) {
        printf("testXmlwriterDoc: Error at xmlTextWriterStartElement\n");
        return;
    }

    /* Write a comment as child of EXAMPLE.
     * Please observe, that the input to the xmlTextWriter functions
     * HAS to be in UTF-8, even if the output XML is encoded
     * in iso-8859-1 */
    tmp = ConvertInput("This is a comment with special chars: <\xE4\xF6\xFC>",
                       MY_ENCODING);
    rc = xmlTextWriterWriteComment(writer, tmp);
    if (rc < 0) {
        printf("testXmlwriterDoc: Error at xmlTextWriterWriteComment\n");
        return;
    }
    if (tmp != NULL) xmlFree(tmp);

    /* Start an element named "ORDER" as child of EXAMPLE. */
    rc = xmlTextWriterStartElement(writer,  "ORDER");
    if (rc < 0) {
        printf("testXmlwriterDoc: Error at xmlTextWriterStartElement\n");
        return;
    }

    /* Add an attribute with name "version" and value "1.0" to ORDER. */
    rc = xmlTextWriterWriteAttribute(writer,  "version",
                                      "1.0");
    if (rc < 0) {
        printf("testXmlwriterDoc: Error at xmlTextWriterWriteAttribute\n");
        return;
    }

    /* Add an attribute with name "xml:lang" and value "de" to ORDER. */
    rc = xmlTextWriterWriteAttribute(writer,  "xml:lang",
                                      "de");
    if (rc < 0) {
        printf("testXmlwriterDoc: Error at xmlTextWriterWriteAttribute\n");
        return;
    }

    /* Write a comment as child of ORDER */
    tmp = ConvertInput("<\xE4\xF6\xFC>", MY_ENCODING);
    rc = xmlTextWriterWriteFormatComment(writer,
		 "This is another comment with special chars: %s",
		                         tmp);
    if (rc < 0) {
        printf
            ("testXmlwriterDoc: Error at xmlTextWriterWriteFormatComment\n");
        return;
    }
    if (tmp != NULL) xmlFree(tmp);

    /* Start an element named "HEADER" as child of ORDER. */
    rc = xmlTextWriterStartElement(writer,  "HEADER");
    if (rc < 0) {
        printf("testXmlwriterDoc: Error at xmlTextWriterStartElement\n");
        return;
    }

    /* Write an element named |"X_ORDER_ID"| as child of HEADER. */
    rc = xmlTextWriterWriteFormatElement(writer,  "X_ORDER_ID",
                                         "%010d", 53535);
    if (rc < 0) {
        printf
            ("testXmlwriterDoc: Error at xmlTextWriterWriteFormatElement\n");
        return;
    }

    /* Write an element named |"CUSTOMER_ID"| as child of HEADER. */
    rc = xmlTextWriterWriteFormatElement(writer,  "CUSTOMER_ID",
                                         "%d", 1010);
    if (rc < 0) {
        printf
            ("testXmlwriterDoc: Error at xmlTextWriterWriteFormatElement\n");
        return;
    }

    /* Write an element named |"NAME_1"| as child of HEADER. */
    tmp = ConvertInput("M\xFCller", MY_ENCODING);
    rc = xmlTextWriterWriteElement(writer,  "NAME_1", tmp);
    if (rc < 0) {
        printf("testXmlwriterDoc: Error at xmlTextWriterWriteElement\n");
        return;
    }
    if (tmp != NULL) xmlFree(tmp);

    /* Write an element named |"NAME_2"| as child of HEADER. */
    tmp = ConvertInput("J\xF6rg", MY_ENCODING);
    rc = xmlTextWriterWriteElement(writer,  "NAME_2", tmp);
    if (rc < 0) {
        printf("testXmlwriterDoc: Error at xmlTextWriterWriteElement\n");
        return;
    }
    if (tmp != NULL) xmlFree(tmp);

    /* Close the element named HEADER. */
    rc = xmlTextWriterEndElement(writer);
    if (rc < 0) {
        printf("testXmlwriterDoc: Error at xmlTextWriterEndElement\n");
        return;
    }

    /* Start an element named "ENTRIES" as child of ORDER. */
    rc = xmlTextWriterStartElement(writer,  "ENTRIES");
    if (rc < 0) {
        printf("testXmlwriterDoc: Error at xmlTextWriterStartElement\n");
        return;
    }

    /* Start an element named "ENTRY" as child of ENTRIES. */
    rc = xmlTextWriterStartElement(writer,  "ENTRY");
    if (rc < 0) {
        printf("testXmlwriterDoc: Error at xmlTextWriterStartElement\n");
        return;
    }

    /* Write an element named "ARTICLE" as child of ENTRY. */
    rc = xmlTextWriterWriteElement(writer,  "ARTICLE",
                                    "<Test>");
    if (rc < 0) {
        printf("testXmlwriterDoc: Error at xmlTextWriterWriteElement\n");
        return;
    }

    /* Write an element named |"ENTRY_NO"| as child of ENTRY. */
    rc = xmlTextWriterWriteFormatElement(writer,  "ENTRY_NO", "%d",
                                         10);
    if (rc < 0) {
        printf
            ("testXmlwriterDoc: Error at xmlTextWriterWriteFormatElement\n");
        return;
    }

    /* Close the element named ENTRY. */
    rc = xmlTextWriterEndElement(writer);
    if (rc < 0) {
        printf("testXmlwriterDoc: Error at xmlTextWriterEndElement\n");
        return;
    }

    /* Start an element named "ENTRY" as child of ENTRIES. */
    rc = xmlTextWriterStartElement(writer,  "ENTRY");
    if (rc < 0) {
        printf("testXmlwriterDoc: Error at xmlTextWriterStartElement\n");
        return;
    }

    /* Write an element named "ARTICLE" as child of ENTRY. */
    rc = xmlTextWriterWriteElement(writer,  "ARTICLE",
                                    "<Test 2>");
    if (rc < 0) {
        printf("testXmlwriterDoc: Error at xmlTextWriterWriteElement\n");
        return;
    }

    /* Write an element named |"ENTRY_NO"| as child of ENTRY. */
    rc = xmlTextWriterWriteFormatElement(writer,  "ENTRY_NO", "%d",
                                         20);
    if (rc < 0) {
        printf
            ("testXmlwriterDoc: Error at xmlTextWriterWriteFormatElement\n");
        return;
    }

    /* Close the element named ENTRY. */
    rc = xmlTextWriterEndElement(writer);
    if (rc < 0) {
        printf("testXmlwriterDoc: Error at xmlTextWriterEndElement\n");
        return;
    }

    /* Close the element named ENTRIES. */
    rc = xmlTextWriterEndElement(writer);
    if (rc < 0) {
        printf("testXmlwriterDoc: Error at xmlTextWriterEndElement\n");
        return;
    }

    /* Start an element named "FOOTER" as child of ORDER. */
    rc = xmlTextWriterStartElement(writer,  "FOOTER");
    if (rc < 0) {
        printf("testXmlwriterDoc: Error at xmlTextWriterStartElement\n");
        return;
    }

    /* Write an element named "TEXT" as child of FOOTER. */
    rc = xmlTextWriterWriteElement(writer,  "TEXT",
                                    "This is a text.");
    if (rc < 0) {
        printf("testXmlwriterDoc: Error at xmlTextWriterWriteElement\n");
        return;
    }

    /* Close the element named FOOTER. */
    rc = xmlTextWriterEndElement(writer);
    if (rc < 0) {
        printf("testXmlwriterDoc: Error at xmlTextWriterEndElement\n");
        return;
    }

    /* Here we could close the elements ORDER and EXAMPLE using the
     * function xmlTextWriterEndElement, but since we do not want to
     * write any other elements, we simply call xmlTextWriterEndDocument,
     * which will do all the work. */
    rc = xmlTextWriterEndDocument(writer);
    if (rc < 0) {
        printf("testXmlwriterDoc: Error at xmlTextWriterEndDocument\n");
        return;
    }

    xmlFreeTextWriter(writer);

    xmlSaveFileEnc(file, doc, MY_ENCODING);

    xmlFreeDoc(doc);
}

@
@(testWriter.c@>=
void
testXmlwriterTree(const char *file)
{
    int rc;
    xmlTextWriterPtr writer;
    xmlDocPtr doc;
    xmlNodePtr node;
    xmlChar *tmp;

    /* Create a new XML DOM tree, to which the XML document will be
     * written */
    doc = xmlNewDoc( XML_DEFAULT_VERSION);
    if (doc == NULL) {
        printf
            ("testXmlwriterTree: Error creating the xml document tree\n");
        return;
    }

    /* Create a new XML node, to which the XML document will be
     * appended */
    node = xmlNewDocNode(doc, NULL,  "EXAMPLE", NULL);
    if (node == NULL) {
        printf("testXmlwriterTree: Error creating the xml node\n");
        return;
    }

    /* Make ELEMENT the root node of the tree */
    xmlDocSetRootElement(doc, node);

    /* Create a new XmlWriter for DOM tree, with no compression. */
    writer = xmlNewTextWriterTree(doc, node, 0);
    if (writer == NULL) {
        printf("testXmlwriterTree: Error creating the xml writer\n");
        return;
    }

    /* Start the document with the xml default for the version,
     * encoding ISO 8859-1 and the default for the standalone
     * declaration. */
    rc = xmlTextWriterStartDocument(writer, NULL, MY_ENCODING, NULL);
    if (rc < 0) {
        printf("testXmlwriterTree: Error at xmlTextWriterStartDocument\n");
        return;
    }

    /* Write a comment as child of EXAMPLE.
     * Please observe, that the input to the xmlTextWriter functions
     * HAS to be in UTF-8, even if the output XML is encoded
     * in iso-8859-1 */
    tmp = ConvertInput("This is a comment with special chars: <\xE4\xF6\xFC>",
                       MY_ENCODING);
    rc = xmlTextWriterWriteComment(writer, tmp);
    if (rc < 0) {
        printf("testXmlwriterTree: Error at xmlTextWriterWriteComment\n");
        return;
    }
    if (tmp != NULL) xmlFree(tmp);

    /* Start an element named "ORDER" as child of EXAMPLE. */
    rc = xmlTextWriterStartElement(writer,  "ORDER");
    if (rc < 0) {
        printf("testXmlwriterTree: Error at xmlTextWriterStartElement\n");
        return;
    }

    /* Add an attribute with name "version" and value "1.0" to ORDER. */
    rc = xmlTextWriterWriteAttribute(writer,  "version",
                                      "1.0");
    if (rc < 0) {
        printf
            ("testXmlwriterTree: Error at xmlTextWriterWriteAttribute\n");
        return;
    }

    /* Add an attribute with name "xml:lang" and value "de" to ORDER. */
    rc = xmlTextWriterWriteAttribute(writer,  "xml:lang",
                                      "de");
    if (rc < 0) {
        printf
            ("testXmlwriterTree: Error at xmlTextWriterWriteAttribute\n");
        return;
    }

    /* Write a comment as child of ORDER */
    tmp = ConvertInput("<\xE4\xF6\xFC>", MY_ENCODING);
    rc = xmlTextWriterWriteFormatComment(writer,
			 "This is another comment with special chars: %s",
					  tmp);
    if (rc < 0) {
        printf
            ("testXmlwriterTree: Error at xmlTextWriterWriteFormatComment\n");
        return;
    }
    if (tmp != NULL) xmlFree(tmp);

    /* Start an element named "HEADER" as child of ORDER. */
    rc = xmlTextWriterStartElement(writer,  "HEADER");
    if (rc < 0) {
        printf("testXmlwriterTree: Error at xmlTextWriterStartElement\n");
        return;
    }

    /* Write an element named |"X_ORDER_ID"| as child of HEADER. */
    rc = xmlTextWriterWriteFormatElement(writer,  "X_ORDER_ID",
                                         "%010d", 53535);
    if (rc < 0) {
        printf
            ("testXmlwriterTree: Error at xmlTextWriterWriteFormatElement\n");
        return;
    }

    /* Write an element named |"CUSTOMER_ID"| as child of HEADER. */
    rc = xmlTextWriterWriteFormatElement(writer,  "CUSTOMER_ID",
                                         "%d", 1010);
    if (rc < 0) {
        printf
            ("testXmlwriterTree: Error at xmlTextWriterWriteFormatElement\n");
        return;
    }

    /* Write an element named |"NAME_1"| as child of HEADER. */
    tmp = ConvertInput("M\xFCller", MY_ENCODING);
    rc = xmlTextWriterWriteElement(writer,  "NAME_1", tmp);
    if (rc < 0) {
        printf("testXmlwriterTree: Error at xmlTextWriterWriteElement\n");
        return;
    }
    if (tmp != NULL) xmlFree(tmp);

    /* Write an element named |"NAME_2"| as child of HEADER. */
    tmp = ConvertInput("J\xF6rg", MY_ENCODING);
    rc = xmlTextWriterWriteElement(writer,  "NAME_2", tmp);
    if (rc < 0) {
        printf("testXmlwriterTree: Error at xmlTextWriterWriteElement\n");
        return;
    }
    if (tmp != NULL) xmlFree(tmp);

    /* Close the element named HEADER. */
    rc = xmlTextWriterEndElement(writer);
    if (rc < 0) {
        printf("testXmlwriterTree: Error at xmlTextWriterEndElement\n");
        return;
    }

    /* Start an element named "ENTRIES" as child of ORDER. */
    rc = xmlTextWriterStartElement(writer,  "ENTRIES");
    if (rc < 0) {
        printf("testXmlwriterTree: Error at xmlTextWriterStartElement\n");
        return;
    }

    /* Start an element named "ENTRY" as child of ENTRIES. */
    rc = xmlTextWriterStartElement(writer,  "ENTRY");
    if (rc < 0) {
        printf("testXmlwriterTree: Error at xmlTextWriterStartElement\n");
        return;
    }

    /* Write an element named "ARTICLE" as child of ENTRY. */
    rc = xmlTextWriterWriteElement(writer,  "ARTICLE",
                                    "<Test>");
    if (rc < 0) {
        printf("testXmlwriterTree: Error at xmlTextWriterWriteElement\n");
        return;
    }

    /* Write an element named |"ENTRY_NO"| as child of ENTRY. */
    rc = xmlTextWriterWriteFormatElement(writer,  "ENTRY_NO", "%d",
                                         10);
    if (rc < 0) {
        printf
            ("testXmlwriterTree: Error at xmlTextWriterWriteFormatElement\n");
        return;
    }

    /* Close the element named ENTRY. */
    rc = xmlTextWriterEndElement(writer);
    if (rc < 0) {
        printf("testXmlwriterTree: Error at xmlTextWriterEndElement\n");
        return;
    }

    /* Start an element named "ENTRY" as child of ENTRIES. */
    rc = xmlTextWriterStartElement(writer,  "ENTRY");
    if (rc < 0) {
        printf("testXmlwriterTree: Error at xmlTextWriterStartElement\n");
        return;
    }

    /* Write an element named "ARTICLE" as child of ENTRY. */
    rc = xmlTextWriterWriteElement(writer,  "ARTICLE",
                                    "<Test 2>");
    if (rc < 0) {
        printf("testXmlwriterTree: Error at xmlTextWriterWriteElement\n");
        return;
    }

    /* Write an element named |"ENTRY_NO"| as child of ENTRY. */
    rc = xmlTextWriterWriteFormatElement(writer,  "ENTRY_NO", "%d",
                                         20);
    if (rc < 0) {
        printf
            ("testXmlwriterTree: Error at xmlTextWriterWriteFormatElement\n");
        return;
    }

    /* Close the element named ENTRY. */
    rc = xmlTextWriterEndElement(writer);
    if (rc < 0) {
        printf("testXmlwriterTree: Error at xmlTextWriterEndElement\n");
        return;
    }

    /* Close the element named ENTRIES. */
    rc = xmlTextWriterEndElement(writer);
    if (rc < 0) {
        printf("testXmlwriterTree: Error at xmlTextWriterEndElement\n");
        return;
    }

    /* Start an element named "FOOTER" as child of ORDER. */
    rc = xmlTextWriterStartElement(writer,  "FOOTER");
    if (rc < 0) {
        printf("testXmlwriterTree: Error at xmlTextWriterStartElement\n");
        return;
    }

    /* Write an element named "TEXT" as child of FOOTER. */
    rc = xmlTextWriterWriteElement(writer,  "TEXT",
                                    "This is a text.");
    if (rc < 0) {
        printf("testXmlwriterTree: Error at xmlTextWriterWriteElement\n");
        return;
    }

    /* Close the element named FOOTER. */
    rc = xmlTextWriterEndElement(writer);
    if (rc < 0) {
        printf("testXmlwriterTree: Error at xmlTextWriterEndElement\n");
        return;
    }

    /* Here we could close the elements ORDER and EXAMPLE using the
     * function xmlTextWriterEndElement, but since we do not want to
     * write any other elements, we simply call xmlTextWriterEndDocument,
     * which will do all the work. */
    rc = xmlTextWriterEndDocument(writer);
    if (rc < 0) {
        printf("testXmlwriterTree: Error at xmlTextWriterEndDocument\n");
        return;
    }

    xmlFreeTextWriter(writer);

    xmlSaveFileEnc(file, doc, MY_ENCODING);

    xmlFreeDoc(doc);
}
@<convert ...@>;


@ converting input into internal UTF-8 encoding using the given encoding.

Memory management: none

@<convert input@>=
xmlChar *
ConvertInput(const char *in, const char *encoding)
{
    xmlChar *out;
    int ret;
    int size;
    int out_size;
    int temp;
    xmlCharEncodingHandlerPtr handler;

    if (in == 0)
        return 0;

    handler = xmlFindCharEncodingHandler(encoding);

    if (!handler) {
        printf("ConvertInput: no encoding handler found for '%s'\n",
               encoding ? encoding : "");
        return 0;
    }

    size = (int) strlen(in) + 1;
    out_size = size * 2 - 1;
    out = (unsigned char *) xmlMalloc((size_t) out_size);

    if (out != 0) {
        temp = size - 1;
        ret = handler->input(out, &out_size, (const xmlChar *) in, &temp);
        if ((ret < 0) || (temp - size + 1)) {
            if (ret < 0) {
                printf("ConvertInput: conversion wasn't successful.\n");
            } else {
                printf
                    ("ConvertInput: conversion wasn't successful. converted: %i octets.\n",
                     temp);
            }

            xmlFree(out);
            out = 0;
        } else {
            out = (unsigned char *) xmlRealloc(out, out_size + 1);
            out[out_size] = 0;  /*null terminating out */
        }
    } else {
        printf("ConvertInput: no mem\n");
    }

    return out;
}
@*IO1.

@(io1.c@>=
#include <stdio.h>
#include <string.h>
#include <libxml/parser.h>
#include <libxml/tree.h>
#include <libxml/xinclude.h>
#include <libxml/xmlIO.h>

static const char *result = "<list><people>a</people><people>b</people></list>";
static const char *cur = NULL;
static int rlen;

static int
sqlMatch(const char * URI) {
    if ((URI != NULL) && (!strncmp(URI, "sql:", 4)))
        return(1);
    return(0);
}

static void *
sqlOpen(const char * URI) {
    if ((URI == NULL) || (strncmp(URI, "sql:", 4)))
        return(NULL);
    cur = result;
    rlen = strlen(result);
    return((void *) cur);
}

static int
sqlClose(void * context) {
    if (context == NULL) return(-1);
    cur = NULL;
    rlen = 0;
    return(0);
}

static int
sqlRead(void * context, char * buffer, int len) {
   const char *ptr = (const char *) context;

   if ((context == NULL) || (buffer == NULL) || (len < 0))
       return(-1);

   if (len > rlen) len = rlen;
   memcpy(buffer, ptr, len);
   rlen -= len;
   return(len);
}

const char *include = "<?xml version='1.0'?>\n"                 @;
"<document xmlns:xi=\"http://www.w3.org/2003/XInclude\">\n"     @;
  "<p>List of people:</p>\n"                                    @;
  "<xi:include href=\"sql:select_name_from_people\"/>\n"        @;
"</document>\n";

int main(void) {
    xmlDocPtr doc;

    LIBXML_TEST_VERSION;

    if (xmlRegisterInputCallbacks(sqlMatch, sqlOpen, sqlRead, sqlClose) < 0) {
        fprintf(stderr, "failed to register SQL handler\n");
	exit(1);
    }

    doc = xmlReadMemory(include, strlen(include), "include.xml", NULL, 0);
    if (doc == NULL) {
        fprintf(stderr, "failed to parse the including file\n");
	exit(1);
    }

    if (xmlXIncludeProcess(doc) <= 0) {
        fprintf(stderr, "XInclude processing failed\n");
	exit(1);
    }

    xmlDocDump(stdout, doc);

    /*
     * Free the document
     */
    xmlFreeDoc(doc);

    /*
     * Cleanup function for the XML library.
     */
    xmlCleanupParser();
    /*
     * this is to debug memory for regression tests
     */
    xmlMemoryDump();
    return(0);
}

@*IO2.

@(io2.c@>=
#include <libxml/parser.h>

int
main(void)
{
    xmlNodePtr n;
    xmlDocPtr doc;
    xmlChar *xmlbuff;
    int buffersize;

    /*
     * Create the document.
     */
    doc = xmlNewDoc(BAD_CAST "1.0");
    n = xmlNewNode(NULL, BAD_CAST "root");
    xmlNodeSetContent(n, BAD_CAST "content");
    xmlDocSetRootElement(doc, n);

    /*
     * Dump the document to a buffer and print it
     * for demonstration purposes.
     */
    xmlDocDumpFormatMemory(doc, &xmlbuff, &buffersize, 1);
    printf("%s", (char *) xmlbuff);

    /*
     * Free associated memory.
     */
    xmlFree(xmlbuff);
    xmlFreeDoc(doc);

    return (0);
}


@*Index.