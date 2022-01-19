#include "config.h"
#include "diskimg.h"
#include "settings.h"
#include "statusword.h"
#include "menu.h"
#include "minfat.h"

#include <stdio.h>

int LoadROM(const char *fn);
int loadimage(char *filename,int unit);

const char *bootvhd_name="BBC     VHD";
const char *bootrom_name="BBC     ROM";

#define BBC_CONFIG_VERSION 0xBBC1 /* "BBC1" */

struct BBC_Config
{
	unsigned short version;
	char scandouble;
	char pad;
	int statusword;
	int statusword2;	/* In case we ever support 64-bit config words */
	int vhd_directory;
	char vhd_name[12];	/* 8.3 + null termination */
	/* 28 bytes so far */
	char pad3[36];	/* For future expansion, brings us to 64 byte boundary */
	char CMOSRAM[64];
};

void configtocore(char *buf)
{
	struct BBC_Config *c=(struct BBC_Config *)buf;
	printf("Copying config to core\n");
	if(c->version==BBC_CONFIG_VERSION)
	{
		int directory=CurrentDirectory();
		printf("Marker is OK\n");
		scandouble=c->scandouble;
		SetScandouble(scandouble);
		statusword=c->statusword;
		sendstatus();

		/* Upload CMOS RAM via data_io */

		/* Change directory, set VHD here.
  		   Must do this last since it will
           trash the sector buffer */
		printf("Loading VHD %s from directory %x\n",c->vhd_name,c->vhd_directory); 
		if(ValidateDirectory(c->vhd_directory))
			ChangeDirectoryByCluster(c->vhd_directory);
		loadimage(c->vhd_name,'0');
	}
	else
	{
		printf("Bad marker - %x\n",c->version);
		Menu_Message("Bad config file",2000);
	}
}

void coretoconfig(char *buf)
{
	struct BBC_Config *c=(struct BBC_Config *)buf;
	printf("Copying core to config\n");
	c->version=BBC_CONFIG_VERSION;
	c->statusword=statusword;
	c->scandouble=scandouble;
	/* Store VHD directory and filename here */
	/* Fetch CMOS RAM from data_io */
}


char *autoboot()
{
    char *result=0;
	/* If a config file didn't cause a disk image to be loaded, attempt to mount a default image */
	if(!diskimg[0].file.size)
	    diskimg_mount(bootvhd_name,0);
	if(!LoadROM(bootrom_name))
		result="ROM loading failed";
    return(result);
}

