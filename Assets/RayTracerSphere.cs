using UnityEngine;

public class RayTracerSphere : MonoBehaviour
{

    public RayTracingMaterial material;
    
    [SerializeField, HideInInspector] int materialObjectID;
    
    void OnValidate()
    {
        MeshRenderer renderer = GetComponent<MeshRenderer>();
        if (renderer != null)
        {
            if (materialObjectID != gameObject.GetInstanceID())
            {
                renderer.sharedMaterial = new Material(renderer.sharedMaterial);
                materialObjectID = gameObject.GetInstanceID();
            }
            renderer.sharedMaterial.color = material.color;
        }
    }

}