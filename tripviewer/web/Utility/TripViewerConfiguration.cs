using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.Extensions.Configuration;

namespace TripViewer.Utility
{

    public class TripViewerConfiguration
    {
        public string BING_MAPS_KEY { get;set; }
        public string USER_ROOT_URL { get; set; }
        public string USER_JAVA_ROOT_URL { get; set; }
        public string TRIPS_ROOT_URL { get; set; }
        public string POI_ROOT_URL { get; set; }
    }
}