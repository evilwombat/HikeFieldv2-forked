#!/usr/bin/env python3

DEFAULT_CONSTANTS = {
}

DEVICES = {
    "d2charlie"         : {'labels' : 'short'},
    "d2delta"           : {'labels' : 'short'},
    "d2deltapx"         : {'labels' : 'short'},
    "d2deltas"          : {'labels' : 'short'},
    "descentmk1"        : {'labels' : 'short'},
    "fenix5"            : {'labels' : 'short'},
    "fenix5plus"        : {'labels' : 'short'},
    "fenix5s"           : {'labels' : 'short'},
    "fenix5splus"       : {'labels' : 'short'},
    "fenix5x"           : {'labels' : 'short'},
    "fenix5xplus"       : {'labels' : 'short'},
    "fenixchronos"      : {'labels' : 'short'},
    "fr55"              : {'labels' : 'short'},
    "fr645"             : {'labels' : 'short'},
    "fr645m"            : {'labels' : 'short'},
    "fr935"             : {'labels' : 'short'},
    "venusq"            : {'labels' : 'short'},
    "venusqm"           : {'labels' : 'short'},

    "approachs60"       : {'labels' : 'mid'},
    "fenix843mm"        : {'labels' : 'mid'},
    "fenix847mm"        : {'labels' : 'mid'},
    "fenixe"            : {'labels' : 'mid'},
    "fr165"             : {'labels' : 'mid'},
    "fr165m"            : {'labels' : 'mid'},
    "fr265"             : {'labels' : 'mid'},
    "fr265s"            : {'labels' : 'mid'},
    "fr955"             : {'labels' : 'mid'},
    "fr965"             : {'labels' : 'mid'},
    "vivoactive3"       : {'labels' : 'mid'},
    "vivoactive3d"      : {'labels' : 'mid'},
    "vivoactive3m"      : {'labels' : 'mid'},
    "vivoactive3mlte"   : {'labels' : 'mid'},
    "vivoactive5"       : {'labels' : 'mid'},
    "venu3"             : {'labels' : 'mid'},
    "venu3s"            : {'labels' : 'mid'},

    "approachs62"       : {'labels' : 'long'},
    "approachs7042mm"   : {'labels' : 'long'},
    "approachs7047mm"   : {'labels' : 'long'},
    "d2air"             : {'labels' : 'long'},
    "d2airx10"          : {'labels' : 'long'},
    "d2mach1"           : {'labels' : 'long'},
    "descentmk2"        : {'labels' : 'long'},
    "descentmk2s"       : {'labels' : 'long'},
    "descentmk343mm"    : {'labels' : 'long'},
    "descentmk351mm"    : {'labels' : 'long'},
    "enduro"            : {'labels' : 'long'},
    "enduro3"           : {'labels' : 'long'},
    "epix2"             : {'labels' : 'long'},
    "epix2pro42mm"      : {'labels' : 'long'},
    "epix2pro47mm"      : {'labels' : 'long'},
    "epix2pro51mm"      : {'labels' : 'long'},
    "fenix6"            : {'labels' : 'long'},
    "fenix6pro"         : {'labels' : 'long'},
    "fenix6s"           : {'labels' : 'long'},
    "fenix6spro"        : {'labels' : 'long'},
    "fenix6xpro"        : {'labels' : 'long'},
    "fenix7"            : {'labels' : 'long'},
    "fenix7pro"         : {'labels' : 'long'},
    "fenix7pronowifi"   : {'labels' : 'long'},
    "fenix7s"           : {'labels' : 'long'},
    "fenix7spro"        : {'labels' : 'long'},
    "fenix7x"           : {'labels' : 'long'},
    "fenix7xpro"        : {'labels' : 'long'},
    "fenix7xpronowifi"  : {'labels' : 'long'},
    "fenix8solar47mm"   : {'labels' : 'long'},
    "fenix8solar51mm"   : {'labels' : 'long'},
    "fr245"             : {'labels' : 'long'},
    "fr245m"            : {'labels' : 'long'},
    "fr255"             : {'labels' : 'long'},
    "fr255m"            : {'labels' : 'long'},
    "fr255s"            : {'labels' : 'long'},
    "fr255sm"           : {'labels' : 'long'},
    "fr735xt"           : {'labels' : 'long'},
    "fr745"             : {'labels' : 'long'},
    "fr945"             : {'labels' : 'long'},
    "fr945lte"          : {'labels' : 'long'},
    "legacyherocaptainmarvel"   : {'labels' : 'long'},
    "legacyherofirstavenger"    : {'labels' : 'long'},
    "legacysagadarthvader"      : {'labels' : 'long'},
    "legacysagarey"     : {'labels' : 'long'},
    "marq2"             : {'labels' : 'long'},
    "marq2aviator"      : {'labels' : 'long'},
    "marqadventurer"    : {'labels' : 'long'},
    "marqathlete"       : {'labels' : 'long'},
    "marqaviator"       : {'labels' : 'long'},
    "marqcaptain"       : {'labels' : 'long'},
    "marqcommander"     : {'labels' : 'long'},
    "marqdriver"        : {'labels' : 'long'},
    "marqexpedition"    : {'labels' : 'long'},
    "marqgolfer"        : {'labels' : 'long'},
    "venu"              : {'labels' : 'long'},
    "venu2"             : {'labels' : 'long'},
    "venu2plus"         : {'labels' : 'long'},
    "venu2s"            : {'labels' : 'long'},
    "venud"             : {'labels' : 'long'},
    "vivoactive4"       : {'labels' : 'long'},
    "vivoactive4s"      : {'labels' : 'long'},
}

def models_shortlabels():
    return [key for key, value in DEVICES.items() if value['labels'] == 'short']

def models_midlabels():
    return [key for key, value in DEVICES.items() if value['labels'] == 'mid']

def models_longlabels():
    return [key for key, value in DEVICES.items() if value['labels'] == 'long']

def models_all():
    return list(DEVICES.keys())