using System.Runtime.InteropServices;
using UnityEngine;

[System.Serializable]

public struct RayTracingMaterial
{
    //public Color colour;
    // public Color emissionColour;
    //public Color specularColour;
    // public float emissionStrength;
    public Color color;
    [Range(0, 1)] public float reflectivity;
    [Range(0, 1)] public float refractivity;
    [Range(0, 1)] public float diffuse;
    [Range(0, 1)] public float refractiveIndex;
    [Range(0, 1)] public float specularProbability;
    [Range(0, 1)] public float smoothness;
    [Range(0, 1)] float emissionStrength; 
    public Color emissionColor;
    public Color specularColor;


    public void SetDefaultValues()
    {
        //   colour = Color.white;
        //  emissionColour = Color.white;
        //  emissionStrength = 0;
        //   specularColour = Color.white;
        //  smoothness = 0;
        //  specularProbability = 1;

        color = Color.white;
        refractivity =0.2f;
         reflectivity =0.2f;
         diffuse =0.2f;
        emissionStrength = 0.5f;
        refractiveIndex = 1;
        specularProbability = 1;
        specularProbability = 1;
     emissionColor = Color.white; ;
     specularColor = Color.white; ;


}
}



