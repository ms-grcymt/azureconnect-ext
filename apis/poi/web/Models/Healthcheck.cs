﻿using System;
using Newtonsoft.Json;

namespace poi.Models
{
    public class Healthcheck
    {
        public Healthcheck()
        {
            Message = "POI Service Healthcheck";
            Status = "Healthy";
            Title = "Azure Connect -new release -liveNOW!";
        }

        [Newtonsoft.Json.JsonProperty(PropertyName = "message")]
        public string Message {get;set;}

        [Newtonsoft.Json.JsonProperty(PropertyName = "status")]
        public string Status { get; set; }

        [Newtonsoft.Json.JsonProperty(PropertyName = "title")]
        public string Title { get; set; }
    }
}
