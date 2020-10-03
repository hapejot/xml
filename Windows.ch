@x
#define XPUBLIC
@y
#define XPUBLIC __declspec(dllexport)
@z

@x
    fp = fopen(file, "w");
@y
    fp = fopen(file, "wb");
@z