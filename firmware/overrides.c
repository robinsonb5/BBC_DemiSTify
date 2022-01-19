#include "config.h"
#include "diskimg.h"
#include "settings.h"
#include "statusword.h"
#include "menu.h"
#include "minfat.h"
#include "spi.h"
#include "uart.h"
#include "user_io.h"

#include <stdio.h>
#include <string.h>

extern unsigned char romtype;
int LoadROM(const char *fn);

static char string[18];

void hexdump(unsigned char *p,unsigned int l)
{
	int i=0;
	unsigned char *p2=p;
	char *sp;
	string[16]=0;
	sp=string;
	while(l--)
	{
		int t,t2;
		t=*p2++;
		t2=t>>4;
		t2+='0'; if(t2>'9') t2+='@'-'9';
		putchar(t2);
		t2=t&0xf;
		t2+='0'; if(t2>'9') t2+='@'-'9';
		putchar(t2);

		if(t<32 || (t>127 && t<160))
			*sp++='.';
		else
			*sp++=t;
		++i;
		if((i&3)==0)
			putchar(' ');
		if((i&15)==0)
		{
			puts(string);
			putchar('\n');
			sp=string;
		}
	}
	if(i&15)
	{
		*sp++=0;
		puts(string);
		putchar('\n');
	}
}

int romdir;
char romname[12];
int vhddir;
char vhdname[12];

__weak int loadimage(char *filename,int unit)
{
	switch(unit)
	{
		case 0:
			romdir=CurrentDirectory();
			romname[0]=0;
			if(filename)
				strncpy(romname,filename,11);
			romname[11]=0;
			return(LoadROM(filename));
			break;
		case '0':
			vhddir=CurrentDirectory();
			vhdname[0]=0;
			if(filename)
				strncpy(vhdname,filename,11);
			vhdname[11]=0;
			printf("Vhdname is now %s\n",vhdname);
		case '1':
			diskimg_mount(0,unit-'0');
			printf("Mounting image\n");
			return(diskimg_mount(filename,unit-'0'));				
			break;
		case 'S':
			return(loadsettings(filename));
			break;
		case 'T':
			return(savesettings(filename));
			break;
	}
}


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
	int rom_directory;
	char rom_filename[12];	/* 8.3 + null termination */
	int vhd_directory;
	char vhd_filename[12];	/* 8.3 + null termination */
	/* 44 bytes so far */
	char pad3[20];	/* For future expansion, brings us to 64 byte boundary */
	char CMOSRAM[64];
};

#define SPIFPGA(a,b) SPI_ENABLE(HW_SPI_FPGA); *spiptr=(a); *spiptr=(b); SPI_DISABLE(HW_SPI_FPGA);

int configtocore(char *buf)
{
	register volatile int *spiptr=&HW_SPI(HW_SPI_DATA);
	char *ptr;
	int result=1;
	struct BBC_Config *c=(struct BBC_Config *)buf;
	printf("Copying config to core\n");
	if(c->version==BBC_CONFIG_VERSION)
	{
		int olddir=CurrentDirectory();
		int i;
		printf("Marker is OK\n");
		scandouble=c->scandouble;
		SetScandouble(scandouble);
		statusword=c->statusword;

		/* Upload CMOS RAM via data_io */

		SPIFPGA(SPI_FPGA_FILE_INDEX,0xff);
		*spiptr=0xff;
		SPIFPGA(SPI_FPGA_FILE_TX,1);
		SPI_ENABLE_FAST_INT(HW_SPI_FPGA);
		*spiptr=SPI_FPGA_FILE_TX_DAT;
		ptr=c->CMOSRAM;
		i=64;
		while(i--)
		{
			*spiptr=*ptr++;
		}
		SPI_DISABLE(HW_SPI_FPGA);

		SPIFPGA(SPI_FPGA_FILE_TX,0);

		/* Retrieve ROM and VHD filenames here */
		romdir=c->rom_directory=romdir;
		strncpy(romname,c->rom_filename,11);
		romname[11]=0;
		vhddir=c->vhd_directory;
		strncpy(vhdname,c->vhd_filename,11);
		vhdname[11]=0;

		/* Now it doesn't matter if we trash the sector buffer. */
		printf("Loading VHD %s from directory %x\n",vhdname,vhddir);
		if(vhdname[0])
		{
			if(ValidateDirectory(vhddir))
				ChangeDirectoryByCluster(vhddir);
			diskimg_mount(0,'0');
			diskimg_mount(vhdname,'0');
		}

		printf("Loading ROM %s from directory %x\n",romname,romdir);
		if(romname[0])
		{
			if(ValidateDirectory(romdir))
				ChangeDirectoryByCluster(romdir);
			romtype=1;
			result=LoadROM(romname);
		}

		ChangeDirectoryByCluster(olddir);

		sendstatus();
	}
	else
	{
		printf("Bad marker - %x\n",c->version);
		Menu_Message("Bad config file",2000);
	}
	return(result);
}

void coretoconfig(char *buf)
{
	register volatile int *spiptr=&HW_SPI(HW_SPI_DATA);
	struct BBC_Config *c=(struct BBC_Config *)buf;
	char *ptr;
	int i;

	printf("Copying core to config\n");
	c->version=BBC_CONFIG_VERSION;
	c->statusword=statusword;
	c->scandouble=scandouble;

	/* Store VHD directory and filename here */
	c->rom_directory=romdir;
	strncpy(c->rom_filename,romname,11);
	c->vhd_directory=vhddir;
	strncpy(c->vhd_filename,vhdname,11);

	/* Fetch CMOS RAM from data_io */
	SPIFPGA(SPI_FPGA_FILE_INDEX,0xff);
	*spiptr=0xff;
	SPIFPGA(SPI_FPGA_FILE_RX,0xff);
	SPI_ENABLE_FAST_INT(HW_SPI_FPGA);
	*spiptr=SPI_FPGA_FILE_RX_DAT;
	ptr=c->CMOSRAM;
	i=64;
	*spiptr=0xff;
	while(i--)
	{
		*spiptr=0xff;
		*ptr++=*spiptr;
	}
	SPI_DISABLE(HW_SPI_FPGA);

	SPIFPGA(SPI_FPGA_FILE_RX,0);

	hexdump(buf,128);
}


char *autoboot()
{
    char *result=0;
	/* If a config file didn't cause a disk image to be loaded, attempt to mount a default image */

	romname[0]=0;
	vhdname[0]=0;
	loadsettings(CONFIG_SETTINGS_FILENAME);

	if(!diskimg[0].file.size)
	    diskimg_mount(bootvhd_name,0);
	romtype=0;
	if(!LoadROM(bootrom_name))
		result="ROM loading failed";
    return(result);
}

