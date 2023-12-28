using DefaultNamespace;
using UnityEngine;
using static UnityEngine.Mathf;

[ExecuteAlways]
public class NewBehaviourScript : MonoBehaviour
{

    [SerializeField] Shader rayTracingShader;
  
    // material that will be used to render the result of the ray tracing shader
    Material rayTracingMaterial;
    
    // Texture : image that is applied over a mesh surface
    // Render Texture : type of Texture that Unity creates and updates at run time
    // create the render texture , assign it to target texture property of the camera
    // then use the render texture as the main texture of the material, just like a regular material 
    RenderTexture resultTexture;
    
    // Event function that Unity calls after a Camera has finished rendering, that allows you to modify the Camera's final image
    // read the pixel from the source image, use shader to modify the pixel and render the result into the target 
    // use blit to copy the result texture to the target 
    
    // if you use many render images on the same objects, they are called in the order in which they appear from top to bottom 
    // the output of one is the input of the next
    
    void OnRenderImage(RenderTexture src, RenderTexture target)
   { 
       if (rayTracingMaterial == null || rayTracingMaterial.shader != rayTracingShader)
       {
           if (rayTracingShader != null)
           {
               rayTracingMaterial = new Material(rayTracingShader);
           }
       }

       //update camera properties 
       float viewport_height = Camera.current.focalLength * Tan(Camera.current.fieldOfView * 0.5f * Deg2Rad) * 2;
       float viewport_width = viewport_height * Camera.current.aspect;
       Vector3 camera_center =Camera.current.transform.position;
       // Send camera data to shader 
       rayTracingMaterial.SetVector("CameraCenter", camera_center);
       rayTracingMaterial.SetVector("Camera", new Vector3( viewport_width, viewport_height, Camera.current.focalLength));

       // create spheres : 
       // Create sphere data from the sphere objects in the scene
       RayTracerSphere[] sphereObjects = FindObjectsByType<RayTracerSphere>(FindObjectsSortMode.None);
       
       Sphere[] spheres = new Sphere[sphereObjects.Length];

       for (int i = 0; i < sphereObjects.Length; i++)
       {
           spheres[i] = new Sphere()
           {
               position = sphereObjects[i].transform.position,
               radius = sphereObjects[i].transform.localScale.x * 0.5f,
               material = sphereObjects[i].material
           };
       }

       // Create buffer containing all sphere data, and send it to the shader
      CreateStructuredBuffer(ref sphereBuffer, spheres);
      rayTracingMaterial.SetBuffer("Spheres", sphereBuffer);
      rayTracingMaterial.SetInt("NumSpheres", sphereObjects.Length);
      
       // Draw result to screen
       // read pixel from source , apply the material resulting from the shader and render the result into the target 
       Graphics.Blit(src, target, rayTracingMaterial);
   }
    
   //arbitrary data to be read & written into memory buffers
   ComputeBuffer sphereBuffer;
   
   // Create a compute buffer containing the given data (Note: data must be blittable)
   public static void CreateStructuredBuffer<T>(ref ComputeBuffer buffer, T[] data) where T : struct
   {
       // Cannot create 0 length buffer 
       int length = Max(1, data.Length);
       // The size (in bytes) of the given data type
       int stride = System.Runtime.InteropServices.Marshal.SizeOf(typeof(T));

       // If buffer is null, wrong size, etc., then we'll need to create a new one
       if (buffer == null || !buffer.IsValid() || buffer.count != length || buffer.stride != stride)
       {
           if (buffer != null) { buffer.Release(); }

           buffer = new ComputeBuffer(length, stride); // default one is ComputeBufferType.Structured; which maps to StructuredBuffer<T> or RWStructuredBuffer<T>.
       }
// set buffer from values from array
       buffer.SetData(data);
   }
   
   void OnDisable()
   {
       Release(sphereBuffer);
       Release(resultTexture);
   }

   // Release compute buffer
   public static void Release(params ComputeBuffer[] buffers)
   {
       for (int i = 0; i < buffers.Length; i++)
       {
           if (buffers[i] != null) 
               buffers[i].Release();
       }
   }
   
// Release render texture
   public static void Release(RenderTexture tex)
   {
       if (tex != null)
       {
           tex.Release();
       }
   }

   
}
