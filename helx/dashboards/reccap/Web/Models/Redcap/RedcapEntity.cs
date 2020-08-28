using System.Text.Json.Serialization;

namespace Renci.ReCCAP.Dashboard.Web.Models.Redcap
{
    public class RedcapEntity
    {
        [JsonPropertyName("study_id")]
        public string study_id { get; set; }

        [JsonPropertyName("compliance_5")]
        public string compliance_5 { get; set; }

        public string compliance_5Text
        {
            get => compliance_5 switch
            {
                "1" => "Bioinformatics Bldg",
                "2" => "Bondurant Hall",
                "3" => "Brinkhous - Bullitt Bldg",
                "4" => "Burnett - Womack Bldg",
                "5" => "Carolina Crossing",
                "6" => "Caudill Lab",
                "7" => "Chapman Hall",
                "8" => "Coker Hall",
                "9" => "Davie Hall",
                "10" => "EPA Bldg",
                "11" => "Fetzer Hall",
                "12" => "Fordham Hall",
                "13" => "Genetic Medicine Research Bldg",
                "14" => "Genome Sciences Buiilding",
                "15" => "Glaxo Research Building",
                "16" => "Hooker Research Center",
                "17" => "Institute Of Marine Sciences",
                "18" => "Kenan Labs",
                "19" => "Kerr Hall",
                "20" => "Koury Oral Health Sciences Bldg",
                "21" => "Lineberger Cancer Research Center",
                "22" => "MacNider Hall",
                "23" => "Marsico Hall",
                "24" => "Mary Ellen Jones",
                "25" => "McGavran - Greenberg Hall",
                "26" => "Meadowmont - Rizzo Conf Ctr",
                "27" => "Medical Biomolecular Research Bldg",
                "28" => "Medical School Wing D",
                "29" => "Murray Hall",
                "30" => "NC Cancer Hospital",
                "31" => "Neurosciences Research Bldg",
                "32" => "Nutrition Research Institute",
                "33" => "Old Clinic Bldg",
                "34" => "Phillips Hall",
                "35" => "Physicians Office Bldg",
                "36" => "Taylor Hall",
                "37" => "Thurston - Bowles Bldg",
                "38" => "UNC Hospitals",
                "39" => "Venable Hall",
                "40" => "Institute of Marine Sciences, Morehead City, NC",
                "41" => "Nutrition Research Institute, Kannapolis, NC",
                "99" => "Other",
                _ => string.Empty
            };
        }

        [JsonPropertyName("compliance_5a")]
        public string compliance_5a { get; set; }

        [JsonPropertyName("mns_01")]
        public string mns_01 { get; set; }

        [JsonPropertyName("mns_result_01")]
        public string mns_result_01 { get; set; }

        public string mns_result_01Text
        {
            get => mns_result_01 switch
            {
                "1" => "Not reported",
                "2" => "Negative",
                "3" => "Positive",
                "4" => "Inconclusive",
                _ => string.Empty
            };
        }

        [JsonPropertyName("mns_result_date_01")]
        public string mns_result_date_01 { get; set; }

        [JsonPropertyName("tasso_01")]
        public string tasso_01 { get; set; }

        [JsonPropertyName("tasso_result_01")]
        public string tasso_result_01 { get; set; }

        public string tasso_result_01Text
        {
            get => tasso_result_01 switch
            {
                "1" => "Not reported",
                "2" => "Negative",
                "3" => "Positive",
                "4" => "Inconclusive",
                _ => string.Empty
            };
        }

        [JsonPropertyName("tasso_result_date_01")]
        public string tasso_result_date_01 { get; set; }

        [JsonPropertyName("gold_cap_01")]
        public string gold_cap_01 { get; set; }

        [JsonPropertyName("gold_cap_result_01")]
        public string gold_cap_result_01 { get; set; }

        public string gold_cap_result_01Text
        {
            get => gold_cap_result_01 switch
            {
                "1" => "Not reported",
                "2" => "Negative",
                "3" => "Positive",
                "4" => "Inconclusive",
                _ => string.Empty
            };
        }

        [JsonPropertyName("gold_cap_result_date_01")]
        public string gold_cap_result_date_01 { get; set; }

        [JsonPropertyName("gold_cap_result_01b")]
        public string gold_cap_result_01b { get; set; }

        public string gold_cap_result_01bText
        {
            get => gold_cap_result_01b switch
            {
                "1" => "Not reported",
                "2" => "Negative",
                "3" => "Positive",
                "4" => "Inconclusive",
                _ => string.Empty
            };
        }

        [JsonPropertyName("gold_cap_result_date_01b")]
        public string gold_cap_result_date_01b { get; set; }

        [JsonPropertyName("saliva_01")]
        public string saliva_01 { get; set; }

        [JsonPropertyName("saliva_result_01")]
        public string saliva_result_01 { get; set; }

        public string saliva_result_01Text
        {
            get => saliva_result_01 switch
            {
                "1" => "Not reported",
                "2" => "Negative",
                "3" => "Positive",
                "4" => "Inconclusive",
                _ => string.Empty
            };
        }

        [JsonPropertyName("saliva_result_date_01")]
        public string saliva_result_date_01 { get; set; }

        [JsonPropertyName("confirm_result_01")]
        public string confirm_result_01 { get; set; }

        public string confirm_result_01Text
        {
            get => confirm_result_01 switch
            {
                "1" => "Not reported",
                "2" => "Negative",
                "3" => "Positive",
                "4" => "Inconclusive",
                _ => string.Empty
            };
        }

        [JsonPropertyName("confirm_loc_01")]
        public string confirm_loc_01 { get; set; }

        public string confirm_loc_01Text
        {
            get => confirm_loc_01 switch
            {
                "1" => "UNC Respiratory Diagnostic Center",
                "2" => "participant's PCP",
                _ => string.Empty
            };
        }

        [JsonPropertyName("mns_02")]
        public string mns_02 { get; set; }

        [JsonPropertyName("mns_result_02")]
        public string mns_result_02 { get; set; }

        public string mns_result_02Text
        {
            get => mns_result_02 switch
            {
                "1" => "Not reported",
                "2" => "Negative",
                "3" => "Positive",
                "4" => "Inconclusive",
                _ => string.Empty
            };
        }

        [JsonPropertyName("mns_result_date_02")]
        public string mns_result_date_02 { get; set; }

        [JsonPropertyName("tasso_02")]
        public string tasso_02 { get; set; }

        [JsonPropertyName("tasso_result_02")]
        public string tasso_result_02 { get; set; }

        public string tasso_result_02Text
        {
            get => tasso_result_02 switch
            {
                "1" => "Not reported",
                "2" => "Negative",
                "3" => "Positive",
                "4" => "Inconclusive",
                _ => string.Empty
            };
        }

        [JsonPropertyName("tasso_result_date_02")]
        public string tasso_result_date_02 { get; set; }

        [JsonPropertyName("saliva_02")]
        public string saliva_02 { get; set; }

        [JsonPropertyName("saliva_result_02")]
        public string saliva_result_02 { get; set; }

        public string saliva_result_02Text
        {
            get => saliva_result_02 switch
            {
                "1" => "Not reported",
                "2" => "Negative",
                "3" => "Positive",
                "4" => "Inconclusive",
                _ => string.Empty
            };
        }

        [JsonPropertyName("saliva_result_date_02")]
        public string saliva_result_date_02 { get; set; }

        [JsonPropertyName("complete_study")]
        public string complete_study { get; set; }

        public string complete_studyText
        {
            get => complete_study switch
            {
                "1" => "Completed",
                "0" => "Withdrawn",
                _ => string.Empty
            };
        }

        [JsonPropertyName("withdraw_date")]
        public string withdraw_date { get; set; }

        [JsonPropertyName("withdraw_reason")]
        public string withdraw_reason { get; set; }

        public string withdraw_reasonText
        {
            get => withdraw_reason switch
            {
                "0" => "Non-compliance",
                "1" => "Did not wish to continue in study",
                "2" => "Could not tolerate the supplement",
                "3" => "Hospitalization",
                "4" => "Other",
                _ => string.Empty
            };
        }
    }
}